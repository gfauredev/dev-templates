{
  description = "Bun/Astro development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    { self, nixpkgs }:
    let
      forSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      nixpkgsFor = forSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          cleanSrc = pkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ] ./.;
        in
        {
          nodeDeps = pkgs.stdenv.mkDerivation {
            pname = "node_modules";
            version = "0.1.0";
            src = cleanSrc;
            nativeBuildInputs = [ pkgs.bun ];
            preBuild = ''
              export HOME=$(mktemp -d)
            '';
            buildPhase = ''
              bun install --no-progress --frozen-lockfile
            '';
            installPhase = ''
              mkdir -p $out
              cp -R ./node_modules $out/node_modules
              rm -rf $out/node_modules/.cache
            '';
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = pkgs.lib.fakeHash;
          };
          site = pkgs.stdenv.mkDerivation {
            pname = "app";
            version = "0.1.0";
            src = cleanSrc;
            nativeBuildInputs = [
              pkgs.bun
              pkgs.nodejs
            ];
            configurePhase = ''
              cp -r ${self.packages.${system}.nodeDeps}/node_modules ./node_modules
              chmod -R +w ./node_modules
              patchShebangs ./node_modules
            '';
            doCheck = true;
            checkPhase = ''
              export HOME=$(mktemp -d)
              export ASTRO_TELEMETRY_DISABLED=1
              bun run check
            '';
            buildPhase = ''
              export HOME=$(mktemp -d)
              export ASTRO_TELEMETRY_DISABLED=1
              bun run build
            '';
            installPhase = ''
              mkdir -p $out
              cp -r dist/* $out/
            '';
          };
          default = self.packages.${system}.site;
        }
      );
      devShells = forSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            packages = with pkgs; [
              astro-language-server # LSP
              jsonfmt
              jq
              prettier
              taplo # TOML LSP
              typescript-language-server # TS LSP
              vscode-langservers-extracted # HTML/CSS/JS(ON)
              yaml-language-server # YAML LSP
            ];
            shellHook = ''
              export ASTRO_TELEMETRY_DISABLED=1 # Problems with sandboxing
              echo "🚀 Astro dev environment loaded (run 'bun install')"
            '';
          };
        }
      );
    };
}
