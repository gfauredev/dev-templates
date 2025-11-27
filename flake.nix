{
  description = "Templates for quickly creating flake-based environments";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Latest NixOS
  outputs =
    { self, nixpkgs }:
    let
      systems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: f { pkgs = nixpkgs.legacyPackages.${system}; }
        );
    in
    {
      devShells = systems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bash-language-server # Bash, shell script LSP
              cachix # CLI for Nix binary cache
              # lorri # Nix development environment daemon
              nil # Nix LSP
              niv # Dependency management
              nixfmt # Formater
              nixfmt-tree # Formater
              nls # Nickel LSP
              shellcheck # Shell script analysis
              shfmt # Shell script formater
              statix # Lints & suggestions for Nix
              vscode-langservers-extracted # HTML/CSS/JS(ON)
              vulnix # NixOS vulnerability scanner
              # haskellPackages.dhall-nix # Dhall to Nix compiler
              taplo # TOML LSP
              yaml-language-server # YAML LSP
            ];
          };
        }
      );
    }
    // {
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
        cad = cadquery-build123d;
        cq = cadquery-build123d;

        c-cpp = {
          path = ./c-cpp;
          description = "C/C++ development environment";
        };
        c = c-cpp;
        cpp = c-cpp;

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
        scad = openscad;

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
        py = python-uv;

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
        rs = rust;

        scala = {
          path = ./scala;
          description = "Scala development environment";
        };

        shell = {
          path = ./shell;
          description = "Shell script development environment";
        };
        sh = shell;

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
        typ = typst;

        vagrant = {
          path = ./vagrant;
          description = "Vagrant development environment";
        };
        vm = vagrant;

        verilog = {
          path = ./verilog;
          description = "Verilog development environment";
        };
        hdl = verilog;

        vlang = {
          path = ./vlang;
          description = "Vlang development environment";
        };

        web = {
          path = ./web;
          description = "Web (HTML/CSS/TS) development environment";
        };
        css = web;
        html = web;
        js = web;
        ts = web;

        zig = {
          path = ./zig;
          description = "Zig development environment";
        };
      };
    };
}
