{
  description = "A Nix-flake-based Python development environment";
  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  # inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux" # "aarch64-linux" # "x86_64-darwin" # "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            # venvDir = ".venv";
            packages =
              with pkgs;
              [
                ruff # Fast lint and format
                ty # Type checker and LSP
                uv # Fast packages and environment manager
                # Web + Misc
                taplo # TOML LSP
                vscode-langservers-extracted # HTML/CSS/JS(ON)
                yaml-language-server # YAML LSP
              ]
              ++ (with pkgs.python3Packages; [
                rope # Smart refactoring
                python-lsp-server # Python LSP
                pylsp-rope # Rope LSP
                # Libraries
                # requests # HTTP requests
                # datetime # Date time
                # numpy # Science & maths tools
                # scipy # Maths & science tools
                # matplotlib # Plotting
                # pandas # Data analysis
                # geopandas # Geo data analysis
                # opencv # Vision
                # tensorflow # Learning
                # matplotlib # Plotting
              ]);
          };
        }
      );
    };
}
