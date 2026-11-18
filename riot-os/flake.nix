{
  description = "RIOT OS Embedded Dev";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      rust-overlay,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Vendor toolchains RIOT pins that nixpkgs lacks (ESP32/ESP8266, xPack RISC-V).
      vendorOverlay = final: prev: {
        riot-vendor = final.callPackage ./nix/toolchains.nix { };
        # nixpkgs bug (unstable, Nov 2026): msp430Newlib runs `lndir` built for the *target*
        # (msp430-none), so pkgsCross.msp430's gcc fails to evaluate. Use the build-host lndir.
        msp430Newlib = prev.msp430Newlib.override { inherit (final.buildPackages) lndir; };
        # TI's MSP Debug Stack uses boost::asio::io_service, removed in Boost 1.87.
        mspds = prev.mspds.override { boost = final.boost186; };
      };

      # One nixpkgs instance per system, overlays applied once.
      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            vendorOverlay
          ];
          # Flip to true (or use allowUnfreePredicate) for segger-jlink, stm32cubeprog, nrf tools, etc.
          config.allowUnfree = false;
        }
      );

      forAllSystems = f: lib.genAttrs systems (system: f pkgsFor.${system});
      availableOn = pkgs: lib.meta.availableOn pkgs.stdenv.hostPlatform;
    in
    {
      overlays.default = vendorOverlay;

      # `nix build .#xtensa-esp-elf` etc. Only what exists for the current system is exposed.
      packages = forAllSystems (
        pkgs:
        lib.filterAttrs (_: availableOn pkgs) (
          lib.removeAttrs pkgs.riot-vendor [
            "override"
            "overrideDerivation"
          ]
        )
        // {
          # Flat directory of udev rules for non-NixOS hosts (see README: "Other Linux distros").
          # NixOS users put the same packages in services.udev.packages instead.
          udev-rules = pkgs.runCommandLocal "riot-dev-udev-rules" { } ''
            mkdir -p $out/lib/udev/rules.d
            for p in ${
              lib.concatMapStringsSep " " toString (
                with pkgs;
                [
                  openocd # ST-Link, CMSIS-DAP, J-Link, FTDI, ESP USB-JTAG, ESP-Prog
                  stlink
                  probe-rs-tools
                  picotool
                  platformio-core.udev # STM32 DFU, Arduino/AVR, CP210x/CH340, MSP430 FETs, …
                ]
              )
            }; do
              for f in $p/lib/udev/rules.d/*.rules $p/etc/udev/rules.d/*.rules; do
                [ -e "$f" ] && cp -L "$f" $out/lib/udev/rules.d/
              done
            done
          '';
        }
      );

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          v = pkgs.riot-vendor;

          # Drop anything not built for the current host instead of failing evaluation.
          avail = builtins.filter (availableOn pkgs);

          llvm = pkgs.llvmPackages_latest;

          # Single source of truth shared with rustup users: ./rust-toolchain.toml
          rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

          python = pkgs.python3.withPackages (
            ps: with ps; [
              pyserial # RIOT pyterm / term
              pexpect # RIOT testrunner
              psutil
              pyelftools
              intelhex
              scapy # 6LoWPAN / IP packet crafting
              cbor2 # SUIT manifests
              cryptography # SUIT signing
              pyyaml
              jinja2
              cmsis-svd # SVD register views in gdb scripts (STM32, nRF, SAM, …)
            ]
          );

          # ================================================================ toolchains
          # One binding per compiler so every shell, clangd and the docs agree.

          # 32-bit ARM Cortex-M + ARM7 (STM32, nRF5x, SAM, Kinetis, EFM32, RP2040, LPC, CC26xx, …).
          # 13.x is the closest to RIOT CI (10.3); RIOT builds with -Werror, and much newer
          # GCCs add warnings. Swap for gcc-arm-embedded (15.x) if your tree is clean with it.
          armGcc = pkgs.gcc-arm-embedded-13;

          # 8-bit AVR (ATmega/ATxmega): built by Hydra (release-cross.nix), so a cache hit.
          avrGcc = pkgs.pkgsCross.avr.buildPackages.gcc; # avr-gcc + avr-libc
          # msp430-elf-gcc + newlib, C only. GCC 16.2's MSP430 backend ICEs (postreload) while
          # building libstdc++, and RIOT has no C++ support on MSP430 anyway, so: GCC 14, no C++.
          msp430Gcc =
            let
              bp = pkgs.pkgsCross.msp430.buildPackages;
            in
            bp.wrapCC (bp.gcc14.cc.override { langCC = false; });

          # RIOT wants TI's device headers *and* linker scripts in $MSP430_SUPPORT_FILES/include;
          # nixpkgs splits them into include/ and lib/ (and marks them msp430-only).
          msp430SupportFiles = pkgs.msp430GccSupport.overrideAttrs (o: {
            pname = "msp430-gcc-support-files-riot";
            buildCommand = o.buildCommand + ''
              for f in $out/lib/*.ld; do ln -s "$f" $out/include/; done
            '';
            meta = o.meta // {
              platforms = lib.platforms.all; # headers + linker scripts only; usable from any host
            };
          });

          # Host gcc for BOARD=native64, host unit tests, -fanalyzer.
          hostGcc = pkgs.gcc;

          # clangd that asks the real cross compilers for sysroot/includes/target macros, so
          # newlib / avr-libc / ESP-IDF headers and __ARM_* / __AVR_* defines resolve from
          # RIOT's compile_commands.json (`make compile-commands`).
          clangd = pkgs.writeShellScriptBin "clangd" ''
            exec ${pkgs.clang-tools}/bin/clangd \
              --query-driver=${
                lib.concatStringsSep "," (
                  [
                    "${armGcc}/bin/arm-none-eabi-*"
                    "${avrGcc}/bin/avr-*"
                    "${msp430Gcc}/bin/msp430-elf-*"
                    "${hostGcc}/bin/*"
                    "/nix/store/*/bin/*-linux-gnu*-g*"
                  ]
                  ++ map (p: "${p}/bin/*") (avail [
                    v.riscv-none-elf
                    v.xtensa-esp-elf
                    v.riscv32-esp-elf
                    v.xtensa-esp8266-elf
                  ])
                )
              } \
              --clang-tidy --background-index --header-insertion=never "$@"
          '';

          # ================================================================ groups
          buildTools = with pkgs; [
            gnumake
            cmake
            ninja
            meson
            pkg-config
            ccache
            bear # compile_commands.json for arbitrary `make` builds
            git
            unzip
            wget
            curl
            which
            dtc
            python
          ];

          cTooling = [
            (lib.hiPrio clangd) # shadows clang-tools' clangd
            pkgs.clang-tools # clang-format, clang-tidy, clang-apply-replacements
            pkgs.clang-analyzer # scan-build / scan-view
            hostGcc
            pkgs.neocmakelsp # CMake LSP (completion, go-to-def, diagnostics, formatting)
            pkgs.gersemi # CMake formatter (`gersemi -i CMakeLists.txt`)
            pkgs.cmake-format # cmakelang's cmake-format, for projects that ship .cmake-format
            pkgs.cmake-lint # CMake linter
            pkgs.include-what-you-use
            pkgs.cppcheck
            pkgs.uncrustify # RIOT's C style (`make static-test`)
          ];

          serial = with pkgs; [
            picocom
            tio
            minicom
          ];

          # --- 32-bit ARM: Cortex-M (incl. STM32) and ARM7
          armTools = with pkgs; [
            armGcc # arm-none-eabi-* with newlib/newlib-nano (TOOLCHAIN=gnu)
            llvm.clang-unwrapped # TOOLCHAIN=llvm; unwrapped so no host cc-wrapper flags leak in
            llvm.lld
            llvm.bintools-unwrapped # llvm-objdump, llvm-size, llvm-nm, …
            openocd # ST-Link, CMSIS-DAP, J-Link (via libjaylink), FTDI
            probe-rs-tools # probe-rs, cargo-flash, cargo-embed; RTT/defmt
            pyocd # CMSIS-Pack based flashing/debug for any Cortex-M
            stlink # st-flash / st-util / st-info
            stm32flash # STM32 UART/I2C ROM bootloader (BOOT0)
            dfu-util # STM32 USB DFU, nRF/SAM DFU bootloaders
            bossa # SAM-BA (Arduino Due/Zero, SAMD)
            picotool # RP2040 / RP2350
          ];

          # --- 32-bit RISC-V (fe310, gd32v, rp2350 Hazard3, NOEL-V)
          riscvTools = avail [ v.riscv-none-elf ];

          # --- 32-bit Xtensa / RISC-V Espressif (ESP32, -S2, -S3, -C3, -C6, -H2, ESP8266)
          espTools =
            avail [
              v.qemu-esp-xtensa # listed first: its qemu-system-xtensa has the esp32 machines
              v.qemu-esp-riscv32
              v.xtensa-esp-elf
              v.riscv32-esp-elf
              v.xtensa-esp-elf-gdb
              v.riscv32-esp-elf-gdb
              v.openocd-esp32
              v.xtensa-esp8266-elf # x86_64 only (upstream binaries)
            ]
            ++ [ pkgs.esptool ];

          # --- 8-bit AVR
          avrTools = with pkgs; [
            avrGcc
            avrdude # PROGRAMMER=avrdude (arduino, stk500, usbasp, jtagice3, …)
            simavr # cycle-accurate AVR simulator with gdb stub (`simavr -g -m atmega328p bin.elf`)
            dfu-programmer # ATmega32U4 / AT90USB DFU bootloaders
          ];

          # --- 16-bit MSP430
          # TI's MSP Debug Stack (tilib driver for eZ-FET / MSP-FET) is marked broken on aarch64;
          # plain mspdebug still covers rf2500, olimex, goodfet, sim, … and its gdb proxy.
          # Set to false to skip it entirely if it fails to build on your nixpkgs.
          withTiMspds = false;
          mspdsOk = withTiMspds && availableOn pkgs pkgs.mspds && !(pkgs.mspds.meta.broken or false);
          msp430Tools = [
            msp430Gcc
            (if mspdsOk then pkgs.mspdebug.override { enableMspds = true; } else pkgs.mspdebug)
          ]
          ++ lib.optional mspdsOk pkgs.mspds;

          rustTools = with pkgs; [
            rustToolchain
            rust-bindgen # riot-sys / riot-wrappers
            cargo-binutils # cargo size / objdump via llvm-tools
            cargo-bloat
            cargo-expand
            cargo-nextest
            cargo-deny
            cargo-generate
            flip-link # zero-cost stack-overflow protection on Cortex-M
            elf2uf2-rs
            svd2rust
          ];

          debugAndSim =
            with pkgs;
            avail [
              gdb # --enable-targets=all: Cortex-M, ARM7, AVR, MSP430, RISC-V, AArch64, host
              llvm.lldb # includes lldb-dap
              qemu # qemu-system-arm (stm32vldiscovery, netduinoplus2, microbit, …) + qemu-user
              renode # full-SoC simulation (many STM32, nRF52, SiFive, …), RIOT supports it
              sigrok-cli
              pulseview
              # tshark/wireshark come from the host: live capture needs a capability-wrapped
              # dumpcap, which the Nix store cannot provide (see README host setup).
            ];

          analysis =
            with pkgs;
            avail [
              flawfinder
              codespell
              shellcheck
              coccinelle # RIOT's semantic patches
              doxygen
              graphviz
              bloaty # firmware size per symbol/section/compile unit
              binwalk
              rizin
              lcov
              gcovr
              # host-side (native64 / ARM Linux userspace)
              valgrind
              rr
              heaptrack
              hotspot
              kdePackages.kcachegrind
              strace
              ltrace
              uftrace
              perf
            ];

          armLinux = [
            pkgs.pkgsCross.aarch64-multiplatform.buildPackages.gcc # aarch64-unknown-linux-gnu-*
            pkgs.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc # armv7l-unknown-linux-gnueabihf-*
            pkgs.mold
          ];

          commonEnv = {
            LIBCLANG_PATH = "${llvm.libclang.lib}/lib"; # bindgen
            MSP430_SUPPORT_FILES = "${msp430SupportFiles}"; # skips RIOT's download of TI files
            CCACHE = "ccache"; # RIOT prefixes every compiler call with it
            hardeningDisable = [ "all" ]; # keep Nix hardening flags out of firmware/debug builds
          };

          banner = name: ''
            if [ -t 1 ]; then
              echo -e "\033[1;34m[${name}]\033[0m RIOT dev shell (${system})"
              for c in arm-none-eabi-gcc avr-gcc msp430-elf-gcc riscv-none-elf-gcc \
                       xtensa-esp32-elf-gcc riscv32-esp-elf-gcc xtensa-esp8266-elf-gcc rustc; do
                command -v $c >/dev/null && printf '  %-24s %s\n' "$c" "$($c --version | head -1)"
              done
              [ -n "''${RIOTBASE:-}" ] || echo "  hint: export RIOTBASE=/path/to/RIOT"
            fi
          '';

          # No host C compiler in stdenv: CC/CXX stay unset, so RIOT's TARGET_ARCH/TOOLCHAIN
          # logic alone picks compilers (host gcc is still on PATH via cTooling).
          mkEmbeddedShell =
            name: packages: extraEnv:
            pkgs.mkShellNoCC (
              commonEnv
              // {
                inherit name packages;
                shellHook = banner name;
              }
              // extraEnv
            );

          base = buildTools ++ cTooling ++ serial ++ [ pkgs.gdb ];
        in
        {
          # Everything, every architecture.
          default = mkEmbeddedShell "riot-full" (
            buildTools
            ++ cTooling
            ++ serial
            ++ espTools # before debugAndSim so ESP qemu wins over upstream qemu
            ++ armTools
            ++ riscvTools
            ++ avrTools
            ++ msp430Tools
            ++ rustTools
            ++ debugAndSim
            ++ analysis
            ++ armLinux
          ) { };

          # 32-bit ARM Cortex-M / ARM7: STM32, nRF5x, SAM, RP2040, Kinetis, EFM32, LPC, …
          #   make BOARD=nucleo-f446re flash term        (ST-Link via openocd)
          #   make BOARD=blackpill-stm32f411ce PROGRAMMER=dfu-util flash
          arm = mkEmbeddedShell "riot-arm" (base ++ armTools ++ rustTools ++ [ pkgs.qemu ]) { };

          # ESP32 / -S2 / -S3 (Xtensa), ESP32-C3 / -C6 / -H2 (RISC-V), ESP8266.
          #   make BOARD=esp32-wroom-32 flash term
          #   make BOARD=esp32c3-devkit EMULATE=1 term   (Espressif QEMU)
          esp = mkEmbeddedShell "riot-esp" (espTools ++ base) { };

          # Generic RISC-V: HiFive1 (fe310), Longan Nano / Seeed GD32V, RP2350 RISC-V, NOEL-V.
          riscv = mkEmbeddedShell "riot-riscv" (
            base
            ++ riscvTools
            ++ [
              pkgs.openocd
              pkgs.qemu
            ]
          ) { };

          # 8-bit AVR (ATmega328P/2560/1284P/32U4/256RFR2, ATxmega). C only: Rust's avr target is
          # tier 3 and RIOT's Rust support doesn't cover AVR.  make BOARD=arduino-uno flash term
          avr = mkEmbeddedShell "riot-avr" (base ++ avrTools) { };

          # 16-bit MSP430 (F1xx/F2xx/F5xx/FRxx). C only.  make BOARD=z1 flash term
          msp430 = mkEmbeddedShell "riot-msp430" (base ++ msp430Tools) { };

          # ARM Linux userspace (cross gcc + Rust *-linux-gnu targets + qemu-user).
          linux = mkEmbeddedShell "arm-linux" (base ++ rustTools ++ armLinux ++ [ pkgs.qemu ]) {
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-unknown-linux-gnu-gcc";
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64 -L ${pkgs.pkgsCross.aarch64-multiplatform.stdenv.cc.libc}";
            CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER = "armv7l-unknown-linux-gnueabihf-gcc";
            CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_RUNNER = "qemu-arm -L ${pkgs.pkgsCross.armv7l-hf-multiplatform.stdenv.cc.libc}";
          };

          # Minimal, non-interactive, all MCU compilers:
          #   nix develop .#ci -c make -C examples/basic/hello-world BOARD=nucleo-f446re
          ci = pkgs.mkShellNoCC (
            commonEnv
            // {
              packages =
                buildTools
                ++ [
                  armGcc
                  avrGcc
                  msp430Gcc
                  hostGcc
                  rustToolchain
                  pkgs.rust-bindgen
                  pkgs.cppcheck
                  pkgs.uncrustify
                ]
                ++ riscvTools
                ++ avail [
                  v.xtensa-esp-elf
                  v.riscv32-esp-elf
                  v.xtensa-esp8266-elf
                ];
            }
          );
        }
        # RIOT `BOARD=native` is 32-bit and needs a multilib host gcc (x86_64 only).
        # `BOARD=native64` works in every shell above (host gcc is in cTooling).
        // lib.optionalAttrs (system == "x86_64-linux") {
          native = (pkgs.mkShell.override { stdenv = pkgs.multiStdenv; }) (
            commonEnv
            // {
              name = "riot-native";
              packages =
                buildTools
                ++ serial
                ++ [
                  pkgs.gdb
                  pkgs.valgrind
                  pkgs.rr
                  rustToolchain
                ]
                ++ lib.remove hostGcc cTooling; # multiStdenv already provides multilib gcc
              shellHook = banner "riot-native";
            }
          );
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      checks = forAllSystems (pkgs: {
        lint =
          pkgs.runCommandLocal "flake-lint"
            {
              nativeBuildInputs = [
                pkgs.nixfmt
                pkgs.statix
                pkgs.deadnix
              ];
            }
            ''
              for f in ${./flake.nix} ${./nix/toolchains.nix}; do
                nixfmt --check $f
                statix check $f
                deadnix --fail $f
              done
              touch $out
            '';
      });
    };
}
