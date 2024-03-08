{
  description = "Iosevka extended ss20 variant + nerd font glyphs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs) lib;

        pkgs = import nixpkgs { inherit system; };
        buildPlans = (fromTOML (builtins.readFile ./private-build-plans.toml)).buildPlans;

        all = pkgs.iosevka.override {
          set = "curlio";
          privateBuildPlan = buildPlans.curlio;
        };

        curlio = pkgs.iosevka.override {
          set = "curlio";

          privateBuildPlan = buildPlans.curlio // {
            widths = {
              normal = {
                shape = 600;
                menu = 5;
                css = "normal";
              };
            };
          };
        };

        curlioCondensed = pkgs.iosevka.override {
          set = "curlio-condensed";

          privateBuildPlan = buildPlans.curlio // {
            widths = {
              normal = {
                shape = 500;
                menu = 3;
                css = "condensed";
              };
            };
          };
        };

        mkFont = font: web:
          pkgs.stdenvNoCC.mkDerivation {
            name = "curlio";
            dontUnpack = true;

            buildInputs = with pkgs; [
              python311Packages.brotli
              python311Packages.fonttools
            ];

            buildPhase = if web then ''
              mkdir -p ttf woff2

              for ttf in ${font}/share/fonts/truetype/*.ttf; do
                cp $ttf .
                name="$(basename $ttf)"
                pyftsubset $ttf \
                  --output-file="$name".woff2 \
                  --flavor=woff2 \
                  --layout-features=* \
                  --desubroutinize \
                  --unicodes="U+0000-0170,U+00D7,U+00F7,U+2000-206F,U+2074,U+20AC,U+2122,U+2190-21BB,U+2212,U+2215,U+F8FF,U+FEFF,U+FFFD,U+00E8"
                cp $ttf ttf
                mv "$name".woff2 woff2
              done
            '' else ''
              mkdir -p ttf
              cp ${font}/share/fonts/truetype/*.ttf ttf
            '';

            installPhase = ''
              mkdir -p $out
              cp -r ttf $out
            '' + lib.optionalString web ''
              cp -r woff2 $out
            '';
          };
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            python3
          ];
        };

        packages = rec {
          default = curlio-ttf;
          all-ttf = mkFont all false;
          all-web = mkFont all true;
          curlio-ttf = mkFont curlio false;
          curlio-web = mkFont curlio true;
          curlio-condensed-ttf = mkFont curlioCondensed false;
          curlio-condensed-web = mkFont curlioCondensed true;
        };
      }
    );
}
