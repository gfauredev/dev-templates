{
  description = "A Nix-flake-based Rust development environment";
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, rust-overlay }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs supportedSystems (system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays =
                [ rust-overlay.overlays.default self.overlays.default ];
            };
          });
    in {
      overlays.default = final: prev: {
        rustToolchain = let rust = prev.rust-bin;
        in if builtins.pathExists ./rust-toolchain.toml then
          rust.fromRustupToolchainFile ./rust-toolchain.toml
        else if builtins.pathExists ./rust-toolchain then
          rust.fromRustupToolchainFile ./rust-toolchain
        else
          rust.stable.latest.default.override {
            extensions = [ "rust-src" "rustfmt" ];
          };
      };
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            cargo-binutils
            cargo-binstall
            cargo-deny
            cargo-edit
            cargo-watch
            clippy # Additional Rust lints
            gitlab-clippy # GitLab Code Quality report
            lldb # Debug adapter
            openssl
            pkg-config
            rust-analyzer # LSP
            rustToolchain
            # Web + Misc
            vscode-langservers-extracted # HTML/CSS/JS(ON)
            taplo # TOML LSP
            yaml-language-server # YAML LSP
          ];
          # env = {
          RUST_LOG = "debug";
          # RUST_SRC_PATH =
          #   "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          # May be needed to display on wayland
          # LD_LIBRARY_PATH =
          #   (with pkgs; lib.makeLibraryPath [ libGL libxkbcommon wayland ]);
          # };
        };
      });
    };
}
