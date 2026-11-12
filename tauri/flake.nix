{
  description = "Tauri React SQLite Dev";
  nixConfig = {
    extra-substituters = [ "https://gfauredev.cachix.org" ];
    extra-trusted-public-keys = [
      "gfauredev.cachix.org-1:mGOZ5I0bDVatgwLhbuTasIiWpVjgCyMFjfIZEPjmQfM="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    agents-jail.url = "github:gfauredev/nix-agents-jail";
  };
  outputs =
    {
      nixpkgs,
      rust-overlay,
      crane,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux" # "aarch64-linux" "aarch64-darwin"
      ];
      androidHostSystems = [
        "x86_64-linux" # "aarch64-darwin"
      ];
      withAndroidEmulator = false; # emulator + system image: several GB
      withPlaywright = false; # Nix-provided browsers for web e2e tests (Linux)
      minLineCoverage = 85;
      wasmCrateDir = ./crates/engine-wasm; # optional wasm-bindgen wrapper for the web build
      # Match compileSdk / the AGP default in src-tauri/gen/android
      androidPlatforms = [
        "35"
        "36"
        "37"
      ];
      androidBuildTools = [
        "35.0.0"
        "36.0.0"
        "37.0.0"
      ];
      overlays = [ rust-overlay.overlays.default ];
      pkgsFor = lib.genAttrs systems (system: import nixpkgs { inherit system overlays; });
      pkgsAndroidFor = lib.genAttrs androidHostSystems (
        system:
        import nixpkgs {
          inherit system overlays;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        }
      );
      readToml = path: if builtins.pathExists path then lib.importTOML path else { };
      readJSON = path: if builtins.pathExists path then lib.importJSON path else { };
      mkProject =
        system:
        let
          pkgs = pkgsFor.${system};
          inherit (pkgs) stdenv;
          inherit (stdenv.hostPlatform) isLinux isDarwin;
          rootToml = readToml ./Cargo.toml;
          appToml = readToml ./src-tauri/Cargo.toml;
          lockToml = readToml ./Cargo.lock;
          resolveVersion =
            v: if builtins.isString v then v else rootToml.workspace.package.version or "0.0.0";
          appName = appToml.package.name or "app";
          appVersion = resolveVersion (appToml.package.version or null);
          webTargets = [ "wasm32-unknown-unknown" ];
          androidTargets = [
            "aarch64-linux-android"
            "armv7-linux-androideabi"
            "i686-linux-android"
            "x86_64-linux-android"
          ];
          # Lets `cargo tauri build --target universal-apple-darwin` find both std libs
          darwinTargets = lib.optionals isDarwin [
            "aarch64-apple-darwin"
            "x86_64-apple-darwin"
          ];
          baseToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          rustToolchain = baseToolchain.override { targets = webTargets ++ darwinTargets; };
          rustToolchainAndroid = baseToolchain.override {
            targets = webTargets ++ darwinTargets ++ androidTargets;
          };
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };
          craneLib = (crane.mkLib pkgs).overrideToolchain (_: rustToolchain);
          # bun installs packages and runs scripts. Node stays available as the
          # runtime for tools that need V8 (e.g. @vitest/coverage-v8); scripts that
          # want bun's runtime can say so with `bun --bun <tool>`
          bun = pkgs.bun;
          nodejs = pkgs.nodejs_24;
          # FIX nixpkgs' sqlx-cli 0.9.0 links the system SQLite but doesn't declare it,
          # so it fails with "cannot find -lsqlite3", to drop once nixpkgs fixes it
          sqlxCli = pkgs.sqlx-cli.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.sqlite ];
          });
          commonLibs = with pkgs; [
            openssl
            sqlite
          ];
          tauriLibs = lib.optionals isLinux (
            with pkgs;
            [
              webkitgtk_4_1
              gtk3
              glib
              glib-networking
              libsoup_3
              cairo
              pango
              gdk-pixbuf
              harfbuzz
              librsvg
              libayatana-appindicator
            ]
          );
          mediaLibs = lib.optionals isLinux (
            with pkgs.gst_all_1;
            [
              gstreamer
              gst-plugins-base
              gst-plugins-good
            ]
          );
          # dlopen()'d by wgpu/winit; drivers come from the host (/run/opengl-driver on NixOS)
          gpuLibs = lib.optionals isLinux (
            with pkgs;
            [
              vulkan-loader
              libGL
              libxkbcommon
              wayland
              libX11
              libXcursor
              libXi
              libXrandr
            ]
          );
          # Fast host linking on Linux, nixpkgs' `mold` is wrapped by Nix's ld-wrapper, so
          # store RPATHs are set, only the host triple is affected, not Android/wasm
          cargoTarget = stdenv.hostPlatform.rust.cargoEnvVarTarget;
          linkerEnv = lib.optionalAttrs isLinux {
            "CARGO_TARGET_${cargoTarget}_LINKER" = "${pkgs.clang}/bin/clang";
            "CARGO_TARGET_${cargoTarget}_RUSTFLAGS" = "-C link-arg=-fuse-ld=mold";
          };
          generated = map lib.fileset.maybeMissing [
            ./flake.nix
            ./flake.lock
            ./bun-hashes.json
            ./.direnv
            ./result
            ./node_modules
            ./dist
            ./coverage
            ./playwright-report
            ./test-results
            ./target
            ./src-tauri/target
            ./src-tauri/gen/android
            ./src-tauri/gen/apple
          ];
          # Everything except build outputs and the flake itself (desktop app build)
          fullSrc = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.difference ./. (lib.fileset.unions generated);
          };
          # Frontend only: Rust edits never re-run the JS checks (except through the
          # wasm engine, which is a separate input)
          jsSrc = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.difference ./. (
              lib.fileset.unions (
                generated
                ++ map lib.fileset.maybeMissing [
                  ./src-tauri
                  ./crates
                  ./Cargo.toml
                  ./Cargo.lock
                  ./rust-toolchain.toml
                ]
              )
            );
          };
          # Rust only (+ tauri.conf.json, icons, capabilities): TS/CSS edits never
          # invalidate the Rust checks
          rustSrc = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              (craneLib.fileset.commonCargoSources ./.)
              (lib.fileset.difference ./src-tauri (
                lib.fileset.unions (
                  map lib.fileset.maybeMissing [
                    ./src-tauri/target
                    ./src-tauri/gen
                  ]
                )
              ))
            ];
          };
          # JavaScript dependencies (bun)
          # node_modules is a fixed-output derivation: `bun install` from bun.lock,
          # with one hash per system (optional native deps differ by platform)
          # Run `update-bun-hash` in the dev shell after changing bun.lock
          pkgJson = readJSON ./package.json;
          scripts = pkgJson.scripts or { };
          bunHashes = readJSON ./bun-hashes.json;
          # The lockfile's hash is part of the name, so a changed bun.lock can never
          # silently reuse a stale node_modules that happens to have the old hash
          lockTag =
            if builtins.pathExists ./bun.lock then
              builtins.substring 0 12 (builtins.hashFile "sha256" ./bun.lock)
            else
              "missing";
          nodeModules = pkgs.stdenvNoCC.mkDerivation {
            pname = "${appName}-node-modules";
            version = lockTag;
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions (
                [
                  ./package.json
                  ./bun.lock
                ]
                ++ map lib.fileset.maybeMissing [
                  ./bunfig.toml
                  ./.npmrc
                  ./patches
                ]
              );
            };
            nativeBuildInputs = [
              bun
              pkgs.cacert
            ];
            impureEnvVars = lib.fetchers.proxyImpureEnvVars;
            dontConfigure = true;
            buildPhase = ''
              runHook preBuild
              export HOME=$TMPDIR
              export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
              bun install --frozen-lockfile --ignore-scripts --no-progress --linker=hoisted
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -R node_modules $out/
              runHook postInstall
            '';
            # No shebang patching here: a fixed-output path may not reference the store.
            dontFixup = true;
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = bunHashes.${system} or lib.fakeHash;
          };
          setupNodeModules = ''
            export HOME=$TMPDIR
            cp -R --reflink=auto ${nodeModules}/node_modules .
            chmod -R u+w node_modules
            patchShebangs --build node_modules
          '';
          updateBunHash = pkgs.writeShellApplication {
            name = "update-bun-hash";
            runtimeInputs = [
              pkgs.jq
              pkgs.git
            ];
            text = ''
              cd "$(git rev-parse --show-toplevel)"
              file=bun-hashes.json
              [ -f "$file" ] || echo '{}' > "$file"
              git add --intent-to-add "$file" bun.lock 2>/dev/null || true
              if log=$(nix build .#node-modules --no-link 2>&1); then
                echo "node_modules hash for ${system} is up to date"
                exit 0
              fi
              hash=$(grep -oE 'got: +sha256-[A-Za-z0-9+/=]+' <<<"$log" | awk '{print $2}' | tail -n1)
              if [ -z "$hash" ]; then
                echo "$log" >&2
                exit 1
              fi
              tmp=$(mktemp)
              jq --arg s "${system}" --arg h "$hash" '.[$s] = $h' "$file" > "$tmp"
              mv "$tmp" "$file"
              echo "${system}: $hash"
              nix build .#node-modules --no-link
            '';
          };
          # Web: optional Rust → wasm engine
          hasWasmCrate = builtins.pathExists (wasmCrateDir + "/Cargo.toml");
          wasmToml = readToml (wasmCrateDir + "/Cargo.toml");
          wasmPkgName = wasmToml.package.name or "engine-wasm";
          wasmLibName = builtins.replaceStrings [ "-" ] [ "_" ] (wasmToml.lib.name or wasmPkgName);
          wasmCrateRel = lib.path.removePrefix ./. wasmCrateDir; # "./crates/engine-wasm"
          wasmOptFlags = lib.concatStringsSep " " [
            "-O3"
            "--enable-bulk-memory"
            "--enable-nontrapping-float-to-int"
            "--enable-sign-ext"
            "--enable-mutable-globals"
            "--enable-reference-types"
            "--enable-multivalue"
          ];
          # wasm-bindgen's CLI must match the crate version in Cargo.lock exactly
          # Use nixpkgs' versioned attribute when there is one; otherwise warn
          wasmBindgenCli =
            let
              locked = lib.findFirst (p: p.name == "wasm-bindgen") null (lockToml.package or [ ]);
              attr = "wasm-bindgen-cli_" + builtins.replaceStrings [ "." ] [ "_" ] locked.version;
              found = builtins.tryEval (pkgs.${attr} or null);
              cli = if found.success && found.value != null then found.value else pkgs.wasm-bindgen-cli;
            in
            if locked == null then
              pkgs.wasm-bindgen-cli
            else
              lib.warnIf (cli.version != locked.version)
                "Cargo.lock has wasm-bindgen ${locked.version} but nixpkgs offers CLI ${cli.version}; pin `wasm-bindgen = \"=${cli.version}\"`."
                cli;
          wasmArgs = {
            pname = wasmPkgName;
            version = resolveVersion (wasmToml.package.version or null);
            src = rustSrc;
            strictDeps = true;
            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
            cargoExtraArgs = "--locked -p ${wasmPkgName}";
            doCheck = false;
          };
          wasmArtifacts = craneLib.buildDepsOnly wasmArgs;
          engineWasm = craneLib.buildPackage (
            wasmArgs
            // {
              cargoArtifacts = wasmArtifacts;
              nativeBuildInputs = [
                wasmBindgenCli
                pkgs.binaryen
              ];
              installPhaseCommand = ''
                mkdir -p $out
                wasm-bindgen --target web --out-dir $out \
                  target/wasm32-unknown-unknown/release/${wasmLibName}.wasm
                wasm-opt ${wasmOptFlags} $out/${wasmLibName}_bg.wasm -o $out/${wasmLibName}_bg.wasm
              '';
            }
          );
          # Same steps as the Nix build, for local development
          buildWasmScript = pkgs.writeShellApplication {
            name = "build-wasm";
            runtimeInputs = [
              wasmBindgenCli
              pkgs.binaryen
            ];
            text = ''
              cd "$(dirname "$(cargo locate-project --workspace --message-format plain)")"
              cargo build --locked --release -p ${wasmPkgName} --target wasm32-unknown-unknown
              out=${wasmCrateRel}/pkg
              wasm-bindgen --target web --out-dir "$out" \
                target/wasm32-unknown-unknown/release/${wasmLibName}.wasm
              wasm-opt ${wasmOptFlags} "$out/${wasmLibName}_bg.wasm" -o "$out/${wasmLibName}_bg.wasm"
              echo "wasm package written to $out"
            '';
          };
          # Puts the Nix-built wasm where the frontend imports it from
          linkWasm = lib.optionalString hasWasmCrate ''
            mkdir -p ${wasmCrateRel}
            rm -rf ${wasmCrateRel}/pkg
            cp -r ${engineWasm} ${wasmCrateRel}/pkg
            chmod -R u+w ${wasmCrateRel}/pkg
          '';
          # Playwright (opt-in)
          # Playwright's own browser downloads don't run on NixOS; nixpkgs ships
          # patched ones, on macOS Playwright's downloads work: `bunx playwright install`
          playwright = pkgs.playwright-driver;
          usePlaywrightBrowsers = withPlaywright && isLinux;
          playwrightEnv = lib.optionalAttrs usePlaywrightBrowsers {
            PLAYWRIGHT_BROWSERS_PATH = "${playwright.browsers}";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
          };
          playwrightShellHook = lib.optionalString usePlaywrightBrowsers ''
            pw=node_modules/@playwright/test/package.json
            if [ -f "$pw" ]; then
              v=$(node -p "require('./$pw').version")
              if [ "$v" != "${playwright.version}" ]; then
                echo "warning: @playwright/test is $v but the Nix browsers are for ${playwright.version}." >&2
                echo "         Run: bun add -d --exact @playwright/test@${playwright.version}" >&2
              fi
            fi
          '';
          # bun-based derivations
          mkBunDerivation =
            {
              name,
              script,
              install ? "mkdir -p $out",
              nativeBuildInputs ? [ ],
              env ? { },
            }:
            pkgs.stdenvNoCC.mkDerivation {
              pname = "${appName}-${name}";
              version = appVersion;
              src = jsSrc;
              nativeBuildInputs = [
                bun
                nodejs
              ]
              ++ nativeBuildInputs;
              env = {
                CI = "true";
              }
              // env;
              dontConfigure = true;
              buildPhase = ''
                runHook preBuild
                ${setupNodeModules}
                ${linkWasm}
                bun run ${script}
                runHook postBuild
              '';
              installPhase = ''
                runHook preInstall
                ${install}
                runHook postInstall
              '';
              dontFixup = true;
            };
          # Packages
          # Static web build (vite `dist/`), deployable to any static host
          webBundle = mkBunDerivation {
            name = "web";
            script = "build";
            install = "cp -r dist $out";
          };
          # Native desktop app for Nix users (Linux: wrapped binary, macOS: .app)
          # tauri.conf.json's beforeBuildCommand should be "bun run build"
          app = rustPlatform.buildRustPackage (finalAttrs: {
            pname = appName;
            version = appVersion;
            src = fullSrc;
            buildAndTestSubdir = "src-tauri";
            cargoLock.lockFile = ./Cargo.lock;
            nativeBuildInputs = [
              pkgs.cargo-tauri.hook
              bun
              nodejs
              pkgs.pkg-config
            ]
            ++ lib.optionals isLinux [ pkgs.wrapGAppsHook3 ];
            buildInputs = commonLibs ++ tauriLibs ++ mediaLibs;
            preBuild = setupNodeModules + linkWasm;
            preFixup = lib.optionalString isLinux ''
              gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath gpuLibs}")
            '';
            doCheck = false; # tests run in `checks`
            meta.mainProgram = finalAttrs.pname;
          });
          # Checks: Rust
          commonArgs = {
            pname = appName;
            version = appVersion;
            src = rustSrc;
            strictDeps = true;
            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = commonLibs ++ tauriLibs;
            # tauri::generate_context! wants frontendDist ("../dist") to exist
            postPatch = ''
              mkdir -p dist
              [ -e dist/index.html ] || echo '<!doctype html>' > dist/index.html
            '';
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          rustChecks = {
            rust-fmt = craneLib.cargoFmt { inherit (commonArgs) pname version src; };
            rust-clippy = craneLib.cargoClippy (
              commonArgs
              // {
                inherit cargoArtifacts;
                cargoClippyExtraArgs = "--workspace --all-targets -- --deny warnings";
              }
            );
            # nextest instrumented by cargo-llvm-cov → result/lcov.info
            rust-test = craneLib.cargoNextest (
              commonArgs
              // {
                inherit cargoArtifacts;
                withLlvmCov = true;
                nativeBuildInputs = commonArgs.nativeBuildInputs ++ [ pkgs.cargo-llvm-cov ];
                cargoNextestExtraArgs = "--workspace --no-tests=warn";
                cargoLlvmCovExtraArgs =
                  "--lcov --output-path $out/lcov.info"
                  + lib.optionalString (minLineCoverage > 0) " --fail-under-lines ${toString minLineCoverage}";
                preBuild = "mkdir -p $out";
              }
            );
            # nextest does not run doctests.
            rust-doctest = craneLib.cargoDocTest (
              commonArgs
              // {
                inherit cargoArtifacts;
                cargoTestExtraArgs = "--workspace";
              }
            );
          }
          // lib.optionalAttrs hasWasmCrate {
            # The engine also compiles and lints cleanly for wasm32.
            rust-clippy-wasm = craneLib.cargoClippy (
              wasmArgs
              // {
                cargoArtifacts = wasmArtifacts;
                cargoClippyExtraArgs = "-- --deny warnings";
              }
            );
          };
          # Checks: frontend, one check per package.json script
          jsCheck =
            script: extra:
            let
              name = "js-" + builtins.replaceStrings [ ":" ] [ "-" ] script;
            in
            lib.optionalAttrs (scripts ? ${script}) {
              ${name} = mkBunDerivation ({ inherit name script; } // extra);
            };
          jsChecks =
            jsCheck "typecheck" { }
            // jsCheck "lint" { }
            // jsCheck "format:check" { }
            # Coverage thresholds live in the test runner's config
            // jsCheck "test:coverage" {
              install = ''
                mkdir -p $out
                if [ -f coverage/lcov.info ]; then cp coverage/lcov.info $out/; fi
              '';
            }
            // lib.optionalAttrs usePlaywrightBrowsers (
              jsCheck "test:e2e" {
                env = playwrightEnv // {
                  FONTCONFIG_FILE = "${pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; }}";
                };
                install = ''
                  mkdir -p $out
                  if [ -d playwright-report ]; then cp -r playwright-report $out/; fi
                '';
              }
            );
          # Dev shells
          desktopShellHook = lib.optionalString isLinux ''
            export LD_LIBRARY_PATH="${lib.makeLibraryPath gpuLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
            export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules"
            # Uncomment if the window is blank (common with NVIDIA + Wayland):
            # export WEBKIT_DISABLE_DMABUF_RENDERER=1
          '';
          mkDevShell =
            {
              name,
              toolchain,
              extraPackages ? [ ],
              extraEnv ? { },
            }:
            pkgs.mkShell {
              inherit name;
              packages = [
                toolchain
                bun
                nodejs
                updateBunHash
                pkgs.cargo-tauri
                pkgs.pkg-config
                pkgs.sqlite-interactive
                sqlxCli
                pkgs.cargo-nextest
                pkgs.cargo-llvm-cov
                pkgs.bacon
                wasmBindgenCli
                pkgs.binaryen
              ]
              ++ lib.optionals hasWasmCrate [ buildWasmScript ]
              ++ lib.optionals isLinux [
                pkgs.clang
                pkgs.mold
                pkgs.vulkan-tools
              ]
              ++ extraPackages;
              buildInputs = commonLibs ++ tauriLibs ++ mediaLibs;
              env = {
                RUST_BACKTRACE = "1";
              }
              // linkerEnv
              // playwrightEnv
              // extraEnv;
              shellHook = desktopShellHook + playwrightShellHook;
            };
          androidShell =
            let
              pkgsA = pkgsAndroidFor.${system};
              jdk = pkgsA.jdk25;
              android = pkgsA.androidenv.composeAndroidPackages (
                {
                  platformVersions = androidPlatforms;
                  buildToolsVersions = androidBuildTools;
                  includeNDK = true;
                  includeEmulator = withAndroidEmulator;
                  includeSystemImages = withAndroidEmulator;
                }
                // lib.optionalAttrs withAndroidEmulator {
                  systemImageTypes = [ "google_apis" ];
                  abiVersions = [ (if stdenv.hostPlatform.isAarch64 then "arm64-v8a" else "x86_64") ];
                }
              );
              sdkRoot = "${android.androidsdk}/libexec/android-sdk";
            in
            mkDevShell {
              name = "tauri-android";
              toolchain = rustToolchainAndroid;
              extraPackages = [
                android.androidsdk
                jdk
              ];
              extraEnv = {
                ANDROID_HOME = sdkRoot;
                ANDROID_SDK_ROOT = sdkRoot;
                NDK_HOME = "${sdkRoot}/ndk-bundle";
                JAVA_HOME = jdk.home;
                # Gradle's downloaded aapt2 is dynamically linked and fails on NixOS;
                # use the patched one from the SDK instead.
                GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkRoot}/build-tools/${lib.last androidBuildTools}/aapt2";
              };
            };
        in
        {
          devShells = {
            default = mkDevShell {
              name = "tauri";
              toolchain = rustToolchain;
            };
          }
          // lib.optionalAttrs (builtins.elem system androidHostSystems) { android = androidShell; };
          packages = {
            default = app;
            inherit app;
            web = webBundle;
            node-modules = nodeModules;
          }
          // lib.optionalAttrs hasWasmCrate { engine-wasm = engineWasm; };
          checks = rustChecks // jsChecks // { web = webBundle; };
        };
      projects = lib.genAttrs systems mkProject;
      perSystem = attr: lib.genAttrs systems (system: projects.${system}.${attr});
    in
    {
      devShells = perSystem "devShells";
      packages = perSystem "packages";
      checks = perSystem "checks";
      formatter = lib.genAttrs systems (system: pkgsFor.${system}.nixfmt-tree);
    };
}
