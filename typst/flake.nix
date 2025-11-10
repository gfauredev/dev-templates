{
  description = "A Nix-flake-based Typst development environment";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                typst # Advanced document processor
                tinymist # Typst LSP
                typstyle # Typst formatter
                ## Serif fonts
                libre-baskerville # Great, stylish serif
                vollkorn # Great serif font
                # merriweather # Serif readable on low res screens
                # gelasio # Serif Georgia replacement
                # noto-fonts-cjk-serif # Chinese, Japanese, Korean Serif
                ## Sans fonts
                fira-go # Great sans with icons
                nacelle # Helvetica equivalent
                # inter # Interesting sans font
                # carlito # Calibri equivalent
                # noto-fonts-cjk-sans # Chinese, Japanese, Korean Sans
                ## Mono fonts
                nerd-fonts.jetbrains-mono
                # nerd-fonts.fira-code
                ## Packages of multiple fonts
                # liberation_ttf # ≃ Times New Roman, Arial, Courier New equivalents
                # noto-fonts # Google well internationalized fonts
                ## Symbols and emoticons
                nerd-fonts.symbols-only # Even more icons and symbols
                # font-awesome # Icons and symbols
                # noto-fonts-emoji # Emojis
              ]
              ++ (with typstPackages; [
                # Typst packages
              ]);
          };
        }
      );
    };
}
