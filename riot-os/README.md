---
lang: en-US
---

# RIOT OS Embedded Project

<!--toc:start-->

- [Tooling and Dependencies](#tooling-and-dependencies)
- [Building and Running](#building-and-running)
  - [NixOS System Setup](#nixos-system-setup)
  - [Other Linux System Setup](#other-linux-system-setup)

<!--toc:end-->

Some C/C++/Rust RIOT OS Embedded Project

## Tooling and Dependencies

| Purpose            | Methodology            |
| ------------------ | ---------------------- |
| Project versioning | [SemVer]               |
| Commit messages    | [Conventional Commits] |
| Branch naming      | [Conventional Branch]  |
| Branching model    | [GitHub Flow]          |
| Changes submission | [GitHub Pull Requests] |
| Issue tracking     | [GitHub Issues]        |

## Building and Running

The project uses [Nix] to download all (proper versions of) required
dependencies, configure the development environment (shell) and build the
application, reproducibly. The [Nix] environment and tooling is defined in
[`flake.nix`], enable it with `nix develop` or automatically at `cd` with an
allowed [`.envrc`](.envrc) (`direnv allow`) via [`direnv`] (recommended).

Release builds must be pure reproducible `nix build`, but faster incremental
builds may be preferred for development speed.

| Shell     | Command                        | Targets / contents                                                                                                                                                                                 |
| --------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default` | `nix develop`                  | Everything below, plus Rust, analysis/profiling, ARM Linux cross                                                                                                                                   |
| `arm`     | `nix develop .#arm`            | 32-bit Cortex-M / ARM7: **STM32**, nRF5x, SAM, RP2040, Kinetis, EFM32, LPC, CC26xx: gcc-arm-embedded 13, clang/lld, openocd, probe-rs, pyOCD, st-link, stm32flash, dfu-util, bossa, picotool, Rust |
| `esp`     | `nix develop .#esp`            | **ESP32 / S2 / S3** (Xtensa), **ESP32-C3 / C6 / H2** (RISC-V), **ESP8266**: Espressif gcc, gdb, openocd, QEMU at RIOT's pinned versions, esptool                                                   |
| `riscv`   | `nix develop .#riscv`          | 32-bit RISC-V: fe310 (HiFive1), gd32v, RP2350-RISC-V, NOEL-V: xPack multilib `riscv-none-elf-gcc` (same as RIOT's Docker image)                                                                    |
| `avr`     | `nix develop .#avr`            | 8-bit ATmega / ATxmega: avr-gcc + avr-libc, avrdude, simavr, dfu-programmer                                                                                                                        |
| `msp430`  | `nix develop .#msp430`         | 16-bit MSP430: msp430-elf-gcc 14 (C only) + TI support files, mspdebug (+ TI tilib on x86_64)                                                                                                      |
| `linux`   | `nix develop .#linux`          | aarch64 / armv7hf Linux userspace, Cargo runners via qemu-user                                                                                                                                     |
| `native`  | `nix develop .#native`         | x86_64 only: multilib gcc for RIOT `BOARD=native` (32-bit), valgrind, rr                                                                                                                           |
| `ci`      | `nix develop .#ci -c make ...` | Every MCU compiler, nothing interactive                                                                                                                                                            |

Cross C/C++ LSPs need a compilation database, create it with:

```sh
make -C $RIOTBASE/examples/basic/hello-world BOARD=nrf52840dk compile-commands   # RIOT-native
bear -- make ...                                                                 # any make project
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                # CMake
```

A dev shell can't change the host. USB access to probes and serial ports, live
packet capture, running ARM Linux binaries and `perf` all need a one-time system
change.

### NixOS System Setup

Place following code in system Nix configuration to set up:

- udev rules for openocd, st-link, probe-rs, picotool and PlatformIO (STM32 DFU,
  AVR/Arduino, USB-serial chips, MSP430 FETs, Espressif USB-JTAG)
- the `dialout`, `plugdev` and `wireshark` groups
- Wireshark with live capture
- aarch64/armv7 emulation (binfmt)
- `perf_event_paranoid = 1`
- direnv with nix-direnv

```nix
# Flakes + keep dev-shell build inputs alive across garbage collection
nix.settings = {
  experimental-features = [
    "nix-command"
    "flakes"
  ];
  keep-outputs = true;
  keep-derivations = true;
};

# Debug probes, bootloaders and USB-serial adapters usable without sudo
services.udev.packages = with pkgs; [
  openocd # ST-Link, CMSIS-DAP, J-Link, FTDI, Espressif USB-JTAG, ESP-Prog
  stlink # ST-Link v1/v2/v3
  probe-rs-tools # every probe probe-rs supports
  picotool # Raspberry Pi RP2040 / RP2350
  platformio-core.udev # STM32 DFU, Arduino/AVR, CP210x/CH340/FTDI, MSP430 FETs, …
];

users.groups.plugdev = { };
users.users.USER.extraGroups = [ # TODO Replace by actual user who develops
  "dialout" # /dev/ttyUSB*, /dev/ttyACM* (RIOT `make term`)
  "plugdev" # probe access for rules that use GROUP="plugdev"
  "wireshark" # live capture with tshark/wireshark
];

# Wireshark with a capability-wrapped dumpcap: live 6LoWPAN / CoAP / 802.15.4 capture
programs.wireshark = {
  enable = true;
  package = pkgs.wireshark; # or pkgs.wireshark-cli for tshark only
};

# Run aarch64 / armv7 Linux binaries transparently (and let Nix build for them)
boot.binfmt.emulatedSystems = [
  "aarch64-linux"
  "armv7l-linux"
];

# perf, rr, hotspot without root
boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

# Auto-enter the dev shell on `cd` (the project ships an .envrc)
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};

# Optional: run unpatched vendor binaries (STM32CubeIDE/CubeProgrammer, SEGGER, TI tools)
# programs.nix-ld.enable = true;
```

### Other Linux System Setup

**1. Install Nix and enable flakes**

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

The official installer needs systemd, sudo, and SELinux disabled or permissive.
On Fedora with SELinux enforcing, use the Determinate installer
(`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`). It
installs Determinate Nix, a Nix distribution with flakes already on, and it
works with this flake.

**2. udev rules** (from the same packages NixOS uses)

```sh
cd /path/to/this/flake
nix build .#udev-rules
sudo cp result/lib/udev/rules.d/*.rules /etc/udev/rules.d/
sudo groupadd -f plugdev
sudo udevadm control --reload-rules && sudo udevadm trigger
```

**3. Groups** (serial ports and probes). The serial group is `dialout` on
Debian, Ubuntu, Fedora and openSUSE, and `uucp` on Arch:

```sh
sudo usermod -aG dialout,plugdev "$USER" # Arch: sudo usermod -aG uucp,plugdev "$USER"
```

Log out and back in afterwards.

**4. Wireshark / tshark with live capture.** Install it from the distro, because
the Nix store can't hold the file capabilities `dumpcap` needs:

| Distro        | Command                                                                                                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Debian/Ubuntu | `sudo apt install tshark wireshark` (answer _Yes_ to non-root capture), then `sudo usermod -aG wireshark "$USER"` |
| Fedora        | `sudo dnf install wireshark-cli wireshark`, then `sudo usermod -aG wireshark "$USER"`                             |
| Arch          | `sudo pacman -S wireshark-cli wireshark-qt`, then `sudo usermod -aG wireshark "$USER"`                            |
| openSUSE      | `sudo zypper install wireshark`, then `sudo usermod -aG wireshark "$USER"`                                        |

**5. Run aarch64/armv7 Linux binaries (binfmt)**

| Distro        | Command                                                   |
| ------------- | --------------------------------------------------------- |
| Debian/Ubuntu | `sudo apt install qemu-user-static binfmt-support`        |
| Fedora        | `sudo dnf install qemu-user-static`                       |
| Arch          | `sudo pacman -S qemu-user-static qemu-user-static-binfmt` |
| openSUSE      | `sudo zypper install qemu-linux-user`                     |

To also let Nix build aarch64 packages through it, add
`extra-platforms = aarch64-linux armv7l-linux` to `/etc/nix/nix.conf` and
restart `nix-daemon`.

**6. perf / rr without root**

```sh
echo 'kernel.perf_event_paranoid = 1' | sudo tee /etc/sysctl.d/60-perf.conf
sudo sysctl --system
```

**7. direnv (optional)**

```sh
nix profile install nixpkgs#direnv nixpkgs#nix-direnv
mkdir -p ~/.config/direnv
echo 'source $HOME/.nix-profile/share/nix-direnv/direnvrc' >> ~/.config/direnv/direnvrc
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc      # or zsh/fish equivalent
```

Then run `direnv allow` in the project.

**Known non-NixOS caveat:** GUI tools from the dev shell (pulseview, hotspot,
kcachegrind) need OpenGL drivers that Nix doesn't see on other distros. Either
run them through [nixGL](https://github.com/nix-community/nixGL)
(`nix run --impure github:nix-community/nixGL -- pulseview`), or install those
from distro package manager.

[Cargo]: https://doc.rust-lang.org/cargo
[cargo test]: https://doc.rust-lang.org/cargo/commands/cargo-test.html
[cargo-llvm-cov]: https://github.com/taiki-e/cargo-llvm-cov
[Clippy]: https://github.com/rust-lang/rust-clippy
[Conventional Commits]: https://www.conventionalcommits.org
[Conventional Branch]: https://conventional-branch.github.io
[direnv]: https://direnv.net
[`direnv`]: https://direnv.net
[`flake.nix`]: flake.nix
[GPL-3.0]: https://www.gnu.org/licenses/gpl-3.0.en.html
[Guilhem Fauré]: https://www.guilhemfau.re
[Git]: https://git-scm.com
[GitHub Pull Requests]: https://github.com/gfauredev/pccompactor/pulls
[GitHub Issues]: https://github.com/gfauredev/pccompactor/issues
[GitHub Flow]: https://githubflow.github.io
[Google OR-Tools]: https://developers.google.com/optimization
[Helix]: https://helix-editor.com
[lcov]: https://github.com/linux-test-project/lcov
[lldb]: https://lldb.llvm.org
[llvm-cov]: https://llvm.org/docs/CommandGuide/llvm-cov.html
[Maestro]: https://maestro.dev
[nextest]: https://nexte.st
[Nix]: https://nixos.org
[pwa]: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps
[pagespeed insights]: https://pagespeed.web.dev
[renovate]: https://www.mend.io/renovate
[rust-analyzer]: https://rust-analyzer.github.io
[rust]: https://www.rust-lang.org
[rustc]: https://doc.rust-lang.org/rustc
[rustdoc]: https://doc.rust-lang.org/rustdoc
[rustfmt]: https://github.com/rust-lang/rustfmt
[VS Code]: https://code.visualstudio.com
[`crates/engine/data`]: crates/engine/data
[SemVer]: https://semver.org
[Serde]: https://serde.rs
[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API
[Rexie]: https://github.com/wasmerio/rexie
[SQLite]: https://www.sqlite.org/index.html
[Rusqlite]: https://github.com/rusqlite/rusqlite
[Reqwest]: https://github.com/seanmonstar/reqwest
[Time]: https://github.com/time-rs/time
[Tokio]: https://tokio.rs
[yellow labs]: https://yellowlab.tools
[Web-sys]: https://rustwasm.github.io/wasm-bindgen/web-sys/index.html
