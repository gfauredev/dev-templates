{
  description = "A Nix-flake-based C/C++ development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs supportedSystems
        (system: f { pkgs = import nixpkgs { inherit system; }; });
    in {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell.override {
          stdenv = pkgs.clangStdenv; # Clang instead of GCC
        } {
          packages = with pkgs; [
            clang-tools # clang CLIs
            cmake # Automation tool
            cmake-language-server # LSP
            cppcheck # Static analysis
            doxygen # Documentation generator
            gnumake # Automation tool
            gtest # Testing framework
            lcov # Code coverage
            lldb # Debug adapter
            pkg-config # Find libraries
            valgrind # Debugging and profiling
          ];
        };
      });
    };
}

