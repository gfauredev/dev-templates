# Prebuilt vendor toolchains that RIOT pins but nixpkgs does not package
# Versions track RIOT's dist/tools/esptools/install.sh and RIOT-OS/riotdocker (riotbuild)
# sha256 values are Espressif's own (ESP-IDF v5.4 tools/tools.json) and xPack's published .sha files
{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  libusb1,
  udev,
  glib,
  libgcrypt,
  libslirp,
  SDL2,
  python312,
}:
let
  inherit (stdenv.hostPlatform) system;
  gh = "https://github.com";

  # Generic "unpack, copy, autoPatchelf" builder for relocatable vendor tarballs.
  prebuilt =
    {
      pname,
      version,
      srcs, # { <nix system> = { url; sha256; }; }
      description,
      homepage,
      license ? lib.licenses.gpl3Plus,
      buildInputs ? [ ],
      ignoreMissing ? [ ],
      postInstall ? "",
      src ? fetchurl (srcs.${system} or (throw "${pname}: no prebuilt for ${system}")),
    }:
    stdenv.mkDerivation {
      inherit
        pname
        version
        src
        postInstall
        ;
      nativeBuildInputs = [
        autoPatchelfHook
        makeWrapper
      ];
      buildInputs = [ stdenv.cc.cc.lib ] ++ buildInputs; # libgcc_s / libstdc++
      autoPatchelfIgnoreMissingDeps = ignoreMissing;
      dontConfigure = true;
      dontBuild = true;
      dontStrip = true; # host strip would mangle target (xtensa/riscv) archives and objects
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -a . $out/
        # Vendor tarballs sometimes ship dangling multilib links (e.g. ESP8266 sysroot/usr/lib{32,64}
        # -> missing lib); they are unused and fail Nix's noBrokenSymlinks check.
        find $out -xtype l -print -delete
        runHook postInstall
      '';
      meta = {
        inherit description homepage license;
        platforms = builtins.attrNames srcs;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    };

  esp = {
    gccRelease = "esp-14.2.0_20241119";
    gccVersion = "14.2.0_20241119";
    gdbVersion = "14.2_20240403";
    openocdVersion = "0.12.0-esp32-20241016";
    qemuVersion = "9.0.0-20240606";
  };

  espGcc =
    target: hashes:
    prebuilt {
      pname = "${target}-gcc";
      version = esp.gccVersion;
      description = "Espressif ${target} GCC (crosstool-NG ${esp.gccRelease}) as pinned by RIOT";
      homepage = "${gh}/espressif/crosstool-NG";
      buildInputs = [ zlib ];
      srcs = {
        x86_64-linux = {
          url = "${gh}/espressif/crosstool-NG/releases/download/${esp.gccRelease}/${target}-${esp.gccVersion}-x86_64-linux-gnu.tar.xz";
          sha256 = hashes.x86_64-linux;
        };
        aarch64-linux = {
          url = "${gh}/espressif/crosstool-NG/releases/download/${esp.gccRelease}/${target}-${esp.gccVersion}-aarch64-linux-gnu.tar.xz";
          sha256 = hashes.aarch64-linux;
        };
      };
    };

  # Espressif's gdb launchers run `python3 -c` to pick a -3.8 … -3.12 build; replace them
  # with fixed wrappers on the 3.12 build (and the chip's Xtensa dynconfig).
  espGdb =
    target: launchers: hashes:
    prebuilt {
      pname = "${target}-gdb";
      version = esp.gdbVersion;
      description = "Espressif ${target} GDB as pinned by RIOT";
      homepage = "${gh}/espressif/binutils-gdb";
      buildInputs = [ python312 ];
      ignoreMissing = map (v: "libpython3.${v}.so.1.0") [
        "8"
        "9"
        "10"
        "11"
      ];
      srcs = {
        x86_64-linux = {
          url = "${gh}/espressif/binutils-gdb/releases/download/esp-gdb-v${esp.gdbVersion}/${target}-gdb-${esp.gdbVersion}-x86_64-linux-gnu.tar.gz";
          sha256 = hashes.x86_64-linux;
        };
        aarch64-linux = {
          url = "${gh}/espressif/binutils-gdb/releases/download/esp-gdb-v${esp.gdbVersion}/${target}-gdb-${esp.gdbVersion}-aarch64-linux-gnu.tar.gz";
          sha256 = hashes.aarch64-linux;
        };
      };
      postInstall = ''
        rm -f $out/bin/${target}-gdb-3.{8,9,10,11}
        ${lib.concatMapStrings (l: ''
          rm -f $out/bin/${l.name}
          makeWrapper $out/bin/${target}-gdb-3.12 $out/bin/${l.name} \
            --set PYTHONHOME ${python312} ${
              lib.optionalString (l ? dynconfig) "--set XTENSA_GNU_CONFIG $out/lib/${l.dynconfig}"
            }
        '') launchers}
      '';
    };

  espQemu =
    arch: hashes:
    prebuilt {
      pname = "qemu-esp-${arch}";
      version = esp.qemuVersion;
      description = "Espressif QEMU fork (${arch}) with ESP32 machines, as pinned by RIOT";
      homepage = "${gh}/espressif/qemu";
      license = lib.licenses.gpl2Plus;
      buildInputs = [
        zlib
        glib
        libgcrypt
        libslirp
        SDL2
      ];
      srcs = {
        x86_64-linux = {
          url = "${gh}/espressif/qemu/releases/download/esp-develop-${esp.qemuVersion}/qemu-${arch}-softmmu-esp_develop_${
            builtins.replaceStrings [ "-" ] [ "_" ] esp.qemuVersion
          }-x86_64-linux-gnu.tar.xz";
          sha256 = hashes.x86_64-linux;
        };
        aarch64-linux = {
          url = "${gh}/espressif/qemu/releases/download/esp-develop-${esp.qemuVersion}/qemu-${arch}-softmmu-esp_develop_${
            builtins.replaceStrings [ "-" ] [ "_" ] esp.qemuVersion
          }-aarch64-linux-gnu.tar.xz";
          sha256 = hashes.aarch64-linux;
        };
      };
    };
in
{
  # ------------------------------------------------------------------ ESP32 family
  # ESP32 / ESP32-S2 / ESP32-S3 (Xtensa LX6/LX7). Provides xtensa-esp32{,s2,s3}-elf-* names RIOT uses.
  xtensa-esp-elf = espGcc "xtensa-esp-elf" {
    x86_64-linux = "e3e6dcf3d275c3c9ab0e4c8a9d93fd10e7efc035d435460576c9d95b4140c676";
    aarch64-linux = "ac2b311dc0003386425086bfc813bf2aeb3cdf3b117845802df6ebef5f69955f";
  };

  # ESP32-C3 / C6 / H2 (RISC-V)
  riscv32-esp-elf = espGcc "riscv32-esp-elf" {
    x86_64-linux = "7faaa86d272f3e43c233f8a5ffeba327673224a752c2eb72394655d5e7950000";
    aarch64-linux = "762eac9ee3d909cf806dcbd26feeb4a83061640d1afea39bc36efdb566b77b03";
  };

  xtensa-esp-elf-gdb =
    espGdb "xtensa-esp-elf"
      (map
        (c: {
          name = "xtensa-${c}-elf-gdb";
          dynconfig = "xtensa_${c}.so";
        })
        [
          "esp32"
          "esp32s2"
          "esp32s3"
          "esp8266" # the ESP8266 toolchain's own gdb needs python2.7; use this one instead
        ]
      )
      {
        x86_64-linux = "9d68472d4cba5cf8c2b79d94f86f92c828e76a632bd1e6be5e7706e5b304d36e";
        aarch64-linux = "bdabc3217994815fc311c4e16e588b78f6596b5ad4ffa46c80b40e982cfb1e66";
      };

  riscv32-esp-elf-gdb = espGdb "riscv32-esp-elf" [ { name = "riscv32-esp-elf-gdb"; } ] {
    x86_64-linux = "ce004bc0bbd71b246800d2d13b239218b272a38bd528e316f21f1af2db8a4b13";
    aarch64-linux = "ba10f2866c61410b88c65957274280b1a62e3bed05131654ed9b6758efe18e55";
  };

  # JTAG debugging of ESP32 over USB-JTAG / ESP-Prog. Installed as `openocd-esp32` so it
  # doesn't shadow upstream openocd: `make ... PROGRAMMER=openocd OPENOCD=openocd-esp32`.
  openocd-esp32 = prebuilt {
    pname = "openocd-esp32";
    version = esp.openocdVersion;
    description = "Espressif OpenOCD fork as pinned by RIOT";
    homepage = "${gh}/espressif/openocd-esp32";
    license = lib.licenses.gpl2Plus;
    buildInputs = [
      zlib
      libusb1
      udev
    ];
    srcs = {
      x86_64-linux = {
        url = "${gh}/espressif/openocd-esp32/releases/download/v${esp.openocdVersion}/openocd-esp32-linux-amd64-${esp.openocdVersion}.tar.gz";
        sha256 = "e82b0f036dc99244bead5f09a86e91bb2365cbcd1122ac68261e5647942485df";
      };
      aarch64-linux = {
        url = "${gh}/espressif/openocd-esp32/releases/download/v${esp.openocdVersion}/openocd-esp32-linux-arm64-${esp.openocdVersion}.tar.gz";
        sha256 = "8f8daf5bd22ec5d2fa9257b0862ec33da18ee677e023fb9a9eb17f74ce208c76";
      };
    };
    postInstall = "mv $out/bin/openocd $out/bin/openocd-esp32";
  };

  # Provide qemu-system-xtensa / qemu-system-riscv32 with esp32 / esp32c3 machines.
  # Listed before upstream qemu in the shells so these names win.
  qemu-esp-xtensa = espQemu "xtensa" {
    x86_64-linux = "071d117c44a6e9a1bc8664ab63b592d3e17ceb779119dcb46c59571a4a7a88c9";
    aarch64-linux = "43552f32b303a6820d0d9551903e54fc221aca98ccbd04e5cbccbca881548008";
  };
  qemu-esp-riscv32 = espQemu "riscv32" {
    x86_64-linux = "47120e826cfec7180db8cb611a7a4aed2e9b2191c2a739194f8ce085e63cdd8d";
    aarch64-linux = "3b6221a8b1881d2c9b9fa0b0bf8d7065c84153d2a54e429307bde9feae235c27";
  };

  # ESP8266 (Xtensa LX106): RIOT clones this exact repo (GCC 5.2, x86_64 only).
  xtensa-esp8266-elf = prebuilt {
    pname = "xtensa-esp8266-elf-gcc";
    version = "5.2.0-unstable-2019-10-18";
    description = "ESP8266 GCC toolchain as used by RIOT (gschorcht/xtensa-esp8266-elf)";
    homepage = "${gh}/gschorcht/xtensa-esp8266-elf";
    src = fetchFromGitHub {
      owner = "gschorcht";
      repo = "xtensa-esp8266-elf";
      rev = "696257c2b43e2a107d3108b2c1ca6d5df3fb1a6f";
      hash = "sha256-9nr7uvdjTULYHz3L83WFq9oB1nIMc9DCd9H3m4TtJpI=";
    };
    srcs.x86_64-linux = null; # platform marker only
    buildInputs = [ zlib ];
    postInstall = "rm -f $out/bin/xtensa-esp8266-elf-gdb"; # needs python2.7; see xtensa-esp-elf-gdb
  };

  # ------------------------------------------------------------------ generic RISC-V
  # Multilib (rv32imac/ilp32, rv64imac/lp64, …) toolchain RIOT's Docker image uses for
  # fe310 (HiFive1), gd32v (Longan Nano), rp2350 Hazard3, NOEL-V. nixpkgs' riscv32-embedded
  # gcc is single-ABI (rv32gc/ilp32d) and cannot link RIOT's rv32imac/ilp32 objects.
  riscv-none-elf = prebuilt rec {
    pname = "xpack-riscv-none-elf-gcc";
    version = "13.2.0-2";
    description = "xPack GNU RISC-V Embedded GCC (multilib) as pinned by RIOT riotdocker";
    homepage = "https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/";
    srcs = {
      x86_64-linux = {
        url = "${gh}/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v${version}/xpack-riscv-none-elf-gcc-${version}-linux-x64.tar.gz";
        sha256 = "52545afb900200fbf65fe05f7ce7090b8a42c64091f4f5d43cae6bb68ea2434a";
      };
      aarch64-linux = {
        url = "${gh}/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v${version}/xpack-riscv-none-elf-gcc-${version}-linux-arm64.tar.gz";
        sha256 = "1c981c611a38dfe5af902089aed570d4dd501eb4ed88d801043e59ab9a62a86a";
      };
    };
    buildInputs = [ zlib ];
    # xPack bundles its own host libs under libexec/ ($ORIGIN rpaths); only gdb's optional
    # python variant links a system libpython.
    ignoreMissing = [ "libpython3*" ];
    postInstall = "rm -rf $out/share/doc";
  };
}
