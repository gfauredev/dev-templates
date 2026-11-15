{
  description = "build123d parametric CAD — reproducible dev environment (uv2nix, NixOS 26.05)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # cadquery-ocp(-novtk) ships manylinux_2_28 wheels for both of these.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Single source of truth: pyproject.toml + uv.lock.
      pyproject = lib.importTOML ./pyproject.toml;
      name = pyproject.project.name;
      module = lib.replaceStrings [ "-" ] [ "_" ] name;

      # Python matching `requires-python` (3.13 = nixpkgs 26.05 default → fully cached).
      pythonFor = pkgs: pkgs.python313;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      # Everything comes from PyPI wheels pinned in uv.lock. uv2nix runs
      # autoPatchelfHook on every wheel and injects the PEP 599 manylinux2014
      # libraries, which covers everything the OCP/OCCT wheel links against
      # (libGL, libX11, expat, zlib, libstdc++, libgcc_s) — no overrides needed.
      lockOverlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

      # Hook for local fixes (patches, extra native libs, tests…).
      overrides = final: prev: {
        ${name} = prev.${name}.overrideAttrs (old: {
          passthru = old.passthru // {
            tests = (old.passthru.tests or { }) // {
              pytest = final.pkgs.stdenv.mkDerivation {
                name = "${name}-pytest";
                src = lib.fileset.toSource {
                  root = ./.;
                  fileset = lib.fileset.unions [
                    ./pyproject.toml
                    ./tests
                  ];
                };
                nativeBuildInputs = [ (final.mkVirtualEnv "${name}-test-env" workspace.deps.all) ];
                dontConfigure = true;
                buildPhase = ''
                  runHook preBuild
                  export HOME=$TMPDIR MPLBACKEND=Agg
                  pytest -q -p no:cacheprovider
                  runHook postBuild
                '';
                installPhase = "touch $out";
              };
            };
          };
        });
      };

      # Editable install: rebuilt only when project metadata changes, never on code edits.
      editableOverrides = final: prev: {
        ${name} = prev.${name}.overrideAttrs (old: {
          src = lib.fileset.toSource {
            root = old.src;
            fileset = lib.fileset.unions [
              (old.src + "/pyproject.toml")
              (old.src + "/README.md")
              (old.src + "/src/${module}/__init__.py")
            ];
          };
        });
      };

      pythonSets = forAllSystems (
        pkgs:
        (pkgs.callPackage pyproject-nix.build.packages { python = pythonFor pkgs; }).overrideScope (
          lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            lockOverlay
            overrides
          ]
        )
      );

      # Libraries OCP needs when uv (not Nix) installs the wheels — only for the `uv` shell.
      ocpRuntimeLibs =
        pkgs: with pkgs; [
          libGL
          libx11
          expat
          zlib
          stdenv.cc.cc.lib
        ];
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          pythonSet = pythonSets.${pkgs.stdenv.hostPlatform.system};
          devEnv = pythonSet.mkVirtualEnv "${name}-dev-env" workspace.deps.all;
        in
        {
          # Runtime-only virtualenv (project + build123d), e.g. for CI or `nix run`.
          default = pythonSet.mkVirtualEnv "${name}-env" workspace.deps.default;

          # Standalone OCP CAD Viewer in the browser (http://127.0.0.1:3939).
          viewer = pkgs.writeShellApplication {
            name = "ocp-viewer";
            runtimeInputs = [ devEnv ];
            text = ''exec python -m ocp_viewer "$@"'';
          };
        }
      );

      apps = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        {
          default = {
            type = "app";
            program = lib.getExe' self.packages.${system}.default "python";
            meta.description = "Python with build123d and this project";
          };
          viewer = {
            type = "app";
            program = lib.getExe self.packages.${system}.viewer;
            meta.description = "Standalone OCP CAD Viewer";
          };
        }
      );

      devShells = forAllSystems (
        pkgs:
        let
          pythonSet = pythonSets.${pkgs.stdenv.hostPlatform.system}.overrideScope (
            lib.composeManyExtensions [
              (workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; })
              editableOverrides
            ]
          );
          devEnv = pythonSet.mkVirtualEnv "${name}-dev-env" workspace.deps.all;
        in
        {
          # Pure & reproducible: Nix-built venv, project installed editable.
          default = pkgs.mkShell {
            packages = [
              devEnv
              pkgs.uv
              pkgs.nixfmt
            ];
            env = {
              UV_NO_SYNC = "1"; # Nix owns the venv; uv only edits pyproject.toml/uv.lock
              UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            '';
          };

          # Escape hatch: plain uv-managed .venv (fast dependency experiments
          # before re-locking). Works on NixOS without nix-ld.
          uv = pkgs.mkShell {
            packages = [
              (pythonFor pkgs)
              pkgs.uv
            ];
            env = {
              UV_PYTHON = (pythonFor pkgs).interpreter;
              UV_PYTHON_DOWNLOADS = "never";
              LD_LIBRARY_PATH = lib.makeLibraryPath (ocpRuntimeLibs pkgs);
            };
            shellHook = ''
              unset PYTHONPATH
              uv sync --frozen && source .venv/bin/activate
            '';
          };
        }
      );

      checks = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        {
          inherit (pythonSets.${system}.${name}.passthru.tests) pytest;
          env = self.packages.${system}.default;
        }
      );
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
