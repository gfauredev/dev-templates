{
  description = "A Nix-flake-based Verilog development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default =
            pkgs.mkShell.override
              {
                stdenv = pkgs.clangStdenv; # Clang instead of GCC
              }
              {
                packages = with pkgs; [
                  # gcc # Compiler
                  svls # SystemVerilog LSP
                  iverilog # Icarus Verilog compiler
                  # clang-tools # Clang CLIs
                  # cmake # Automation tool
                  # cmake-language-server # LSP
                  # cppcheck # Static analysis
                  # clang-uml # Generate UML from c(++) TEST it
                  doxygen # Documentation generator
                  # gnumake # Automation tool
                  # gtest # Testing framework
                  # lcov # Code coverage
                  # lldb # Debug adapter
                  # pkg-config # Find libraries
                  # valgrind # Debugging and profiling
                ];
                env = {
                  # CXX = "c++"; # Use Clang++ as the default C++ compiler
                  # CC = "clang"; # Use Clang as the default C compiler
                  # CXXFLAGS = ''
                  #   -std=c++23 -Wall -Wextra -Wpedantic -Wshadow -Wconversion
                  # ''; # C++23 and more warnings
                };
              };
        }
      );
    };
}
