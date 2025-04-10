{
  description = "A Nix-flake-based C/C++ development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
  # inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 

  outputs = { self, nixpkgs }:
    # let
    #   supportedSystems =
    #     [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    #   forEachSupportedSystem = f:
    #     nixpkgs.lib.genAttrs supportedSystems
    #     (system: f { pkgs = import nixpkgs { inherit system; }; });
    # in
    {
      devShells =
        # forEachSupportedSystem ({ pkgs }: {
        #   default = pkgs.mkShell.override {
        #     stdenv = pkgs.clangStdenv; # Clang instead of GCC
        # }
        {
          packages = with pkgs; [
            chicken # Portable compiler for Scheme
            gambit # Scheme to C
            guile # Embeddable Scheme
            # akku # Package manager Scheme
            # mitscheme # Native code Scheme compiler
            # mitschemeX11 # Native code Scheme compiler
            # bigloo # Scheme compiler
          ];
        };
      # });
    };
}

