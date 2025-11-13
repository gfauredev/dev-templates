{
  description = "Nix Flake Lisp and Lisp likes development environment";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
  outputs =
    { self, nixpkgs }:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            f {
              pkgs = import nixpkgs {
                inherit system;
                # overlays = [ self.overlays.default ];
              };
            }
          );
    in
    {
      # overlays.default = final: prev: let
      #     jdk = prev.jdk23;
      #   in {
      #     boot = prev.boot.override { inherit jdk; };
      #     clojure = prev.clojure.override { inherit jdk; };
      #     leiningen = prev.leiningen.override { inherit jdk; };
      #   };
      devShells = eachSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              boot # Clojure's build tool
              clojure # Clojure language
              chez # Chez Scheme implementation
              guile # GNU Guile Scheme implementation
              leiningen # Clojure project automation tool
              racket # Scheme dialect
              sbcl # Common Lisp compiler
              steel # Embedded scheme interpreter
            ];
          };
        }
      );
    };
}
