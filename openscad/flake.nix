{
  description = "A Nix-flake-based OpenSCAD development environment";

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
        default = pkgs.mkShell {
          packages = with pkgs; [
            openscad # Main tool, CAD compiler
            openscad-lsp # OpenSCAD LSP
            sca2d # OpenSCAD static analysis
            # turbocase # Auto generate a case from a KiCAD PCB
            # freecad # GUI
          ];
        };
      });
    };
}
