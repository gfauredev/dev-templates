{
  description = "Nix flake Verilog development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # clang-tools # Clang CLIs
              # cmake # Automation tool
              # cmake-language-server # LSP
              doxygen # Documentation generator
              # gnumake # Automation tool
              iverilog # Icarus Verilog compiler
              # pkg-config # Find libraries
              svls # SystemVerilog LSP
              verilator
              vhd2vl
            ];
          };
        }
      );
    };
}
