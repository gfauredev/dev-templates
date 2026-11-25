{
  description = "Node.js/Bun + Python dev environment";
  # Channel tarball instead of github:NixOS/nixpkgs:
  #  - ~10x smaller download than a GitHub snapshot,
  #  - only advances once Hydra has built it, so everything is in cache.nixos.org,
  #  - still fully locked (the server answers with an immutable URL + narHash).
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  # inputs.nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems =
        f:
        lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          # ── Pick versions here ──────────────────────────────────────────
          python = pkgs.python313; # or python314
          nodejs = pkgs.nodejs_24; # current LTS; or nodejs_22 / nodejs_26
          bun = pkgs.bun;
          # Shared tooling present in every shell.
          common = [
            python
            pkgs.uv
            pkgs.ruff
            # pkgs.basedpyright
            # pkgs.biome
          ];
          # Libraries that prebuilt manylinux wheels (numpy, pydantic-core,
          # grpcio, ...) expect to find. glibc is intentionally NOT listed:
          # leaking a foreign libc through LD_LIBRARY_PATH is what breaks
          # unrelated programs (incl. your Nushell) once direnv exports it.
          wheelLibs = with pkgs; [
            stdenv.cc.cc # libstdc++, libgcc_s
            zlib
            # libGL glib xorg.libX11   # opencv, matplotlib GUI backends, ...
          ];
          mkDevShell =
            name: jsPackages:
            pkgs.mkShell {
              inherit name;
              packages = jsPackages ++ common;
              # Plain env vars: these survive into Nushell (direnv or
              # `nix develop -c nu`), unlike bash functions/aliases/`source`.
              # (No UV_PYTHON: it would make `uv pip` target the read-only Nix
              # Python instead of .venv. The venv below pins the interpreter.)
              env = {
                UV_PYTHON_DOWNLOADS = "never"; # never fetch a foreign Python
                UV_PYTHON_PREFERENCE = "only-system";
              }
              // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
                LD_LIBRARY_PATH = lib.makeLibraryPath wheelLibs;
              };
              # Exports only (no aliases/functions) so it is shell-agnostic.
              shellHook = ''
                # Undo Nix build-time Python settings that hurt interactive use.
                unset PYTHONPATH PYTHONHASHSEED
                export PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
                export UV_PROJECT_ENVIRONMENT="$PROJECT_ROOT/.venv"
                export VIRTUAL_ENV="$UV_PROJECT_ENVIRONMENT"
                export PATH="$PROJECT_ROOT/node_modules/.bin:$VIRTUAL_ENV/bin:$PATH"
                # Python project? Make sure the venv exists, built on Nix's Python.
                for f in "$PROJECT_ROOT"/pyproject.toml "$PROJECT_ROOT"/requirements*.txt; do
                  if [ -e "$f" ] && [ ! -e "$VIRTUAL_ENV/pyvenv.cfg" ]; then
                    uv venv --quiet --python ${python.interpreter} "$VIRTUAL_ENV"
                  fi
                done
              '';
            };
        in
        {
          node = mkDevShell "node" [ nodejs ];
          bun = mkDevShell "bun" [ bun ]; # `bun run` shims `node` itself
          both = mkDevShell "node+bun" [
            nodejs
            bun
          ];
          # ── Swap runtime here (or per-checkout: `use flake .#bun`) ──
          default = self.devShells.${pkgs.stdenv.hostPlatform.system}.node;
        }
      );
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
