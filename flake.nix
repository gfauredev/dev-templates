{
  description = "Templates for quickly creating flake-based environments";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2411.*";
  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs supportedSystems
        (system: f { pkgs = nixpkgs.legacyPackages.${system}; });

      scriptDrvs = forEachSupportedSystem ({ pkgs }:
        let
          getSystem =
            "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
          forEachDir = exec: ''
            for dir in */; do
              (
                cd "''${dir}"

                ${exec}
              )
            done
          '';
        in {
          format = pkgs.writeShellApplication {
            name = "format";
            runtimeInputs = with pkgs; [ nixpkgs-fmt ];
            text = ''
              shopt -s globstar

              nixpkgs-fmt -- **/*.nix
            '';
          };

          # only run this locally, as Actions will run out of disk space
          build = pkgs.writeShellApplication {
            name = "build";
            text = ''
              ${getSystem}

              ${forEachDir ''
                echo "building ''${dir}"
                nix build ".#devShells.''${SYSTEM}.default"
              ''}
            '';
          };

          check = pkgs.writeShellApplication {
            name = "check";
            text = forEachDir ''
              echo "checking ''${dir}"
              nix flake check --all-systems --no-build
            '';
          };

          update = pkgs.writeShellApplication {
            name = "update";
            text = forEachDir ''
              echo "updating ''${dir}"
              nix flake update
            '';
          };
        });
    in {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with scriptDrvs.${pkgs.system};
            [ build check format update ] ++ (with pkgs; [
              bash-language-server # Bash, shell script LSP
              cachix # CLI for Nix binary cache
              lorri # To TEST
              nil # Nix LSP
              niv # Dependency management
              nixfmt # Formater
              nls # Nickel LSP
              shellcheck # Shell script analysis
              shfmt # Shell script formater
              statix # Lints & suggestions for Nix
              vscode-langservers-extracted # HTML/CSS/JS(ON)
              vulnix # NixOS vulnerability scanner
              haskellPackages.dhall-nix # To TEST
              taplo # TOML LSP
              yaml-language-server # YAML LSP
            ]);
        };
      });
    } // {
      templates = rec {
        default = empty;

        bun = {
          path = ./bun;
          description = "Bun development environment";
        };

        cadquery-build123d = {
          path = ./cadquery-build123d;
          description = "CadQuery / Build123d environment";
        };

        c-cpp = {
          path = ./c-cpp;
          description = "C/C++ development environment";
        };

        clojure = {
          path = ./clojure;
          description = "Clojure development environment";
        };

        cue = {
          path = ./cue;
          description = "Cue development environment";
        };

        dhall = {
          path = ./dhall;
          description = "Dhall development environment";
        };

        elixir = {
          path = ./elixir;
          description = "Elixir development environment";
        };

        elm = {
          path = ./elm;
          description = "Elm development environment";
        };

        empty = {
          path = ./empty;
          description = "Empty dev template that you can customize at will";
        };

        gleam = {
          path = ./gleam;
          description = "Gleam development environment";
        };

        go = {
          path = ./go;
          description = "Go (Golang) development environment";
        };

        hashi = {
          path = ./hashi;
          description = "HashiCorp DevOps tools development environment";
        };

        haskell = {
          path = ./haskell;
          description = "Haskell development environment";
        };

        java = {
          path = ./java;
          description = "Java development environment";
        };

        jupyter = {
          path = ./jupyter;
          description = "Jupyter development environment";
        };

        kotlin = {
          path = ./kotlin;
          description = "Kotlin development environment";
        };

        latex = {
          path = ./latex;
          description = "LaTeX development environment";
        };

        lua = {
          path = ./lua;
          description = "Lua development environment";
        };

        lean4 = {
          path = ./lean4;
          description = "Lean 4 development environment";
        };

        nickel = {
          path = ./nickel;
          description = "Nickel development environment";
        };

        nim = {
          path = ./nim;
          description = "Nim development environment";
        };

        nix = {
          path = ./nix;
          description = "Nix development environment";
        };

        node = {
          path = ./node;
          description = "Node.js development environment";
        };

        ocaml = {
          path = ./ocaml;
          description = "OCaml development environment";
        };

        openscad = {
          path = ./openscad;
          description = "OpenSCAD";
        };

        opa = {
          path = ./opa;
          description = "Open Policy Agent development environment";
        };

        php = {
          path = ./php;
          description = "PHP development environment";
        };

        platformio = {
          path = ./platformio;
          description = "PlatformIO development environment";
        };

        protobuf = {
          path = ./protobuf;
          description = "Protobuf development environment";
        };

        pulumi = {
          path = ./pulumi;
          description = "Pulumi development environment";
        };

        purescript = {
          path = ./purescript;
          description = "Purescript development environment";
        };

        python = {
          path = ./python;
          description = "Python development environment";
        };

        python-uv = {
          path = ./python-uv;
          description = "Python uv development environment";
        };

        r = {
          path = ./r;
          description = "R development environment";
        };

        ruby = {
          path = ./ruby;
          description = "Ruby development environment";
        };

        rust = {
          path = ./rust;
          description = "Rust development environment";
        };

        rust-toolchain = {
          path = ./rust-toolchain;
          description =
            "Rust development environment with Rust version defined by a rust-toolchain.toml file";
        };

        scala = {
          path = ./scala;
          description = "Scala development environment";
        };

        shell = {
          path = ./shell;
          description = "Shell script development environment";
        };

        swi-prolog = {
          path = ./swi-prolog;
          description = "Swi-prolog development environment";
        };

        swift = {
          path = ./swift;
          description = "Swift development environment";
        };

        typst = {
          path = ./typst;
          description = "Typst development environment";
        };

        vlang = {
          path = ./vlang;
          description = "Vlang developent environment";
        };

        zig = {
          path = ./zig;
          description = "Zig development environment";
        };

        # Aliases
        c = c-cpp;
        cpp = c-cpp;
        cad = cadquery-build123d;
        cq = cadquery-build123d;
        py = python-uv;
        rs = rust-toolchain;
        rt = rust-toolchain;
        scad = openscad;
        typ = typst;
      };
    };
}
