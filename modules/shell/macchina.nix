{
  # TODO should I use fastfetch instead? I want something with maximum features
  # TODO what about sysfex https://github.com/mehedirm6244/sysfex
  # TODO durdraw also looks fun: https://github.com/cmang/durdraw/tree/dev
  canivete.deploy.system.homeModules.macchina = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkPackageOption mkOption mkIf substring types;
    inherit (pkgs) stdenv formats fetchFromGitHub fetchurl yq;
    cfg = config.dotfiles.programs.macchina;
  in {
    options.dotfiles.programs.macchina = {
      enable = mkEnableOption "macchina";
      package = mkPackageOption pkgs "macchina" {};
      networkInterface = mkOption {
        type = types.str;
        default = "en0";
        example = "wlan0";
        description = "Network interface to display a local IP for";
      };
    };
    config = mkIf cfg.enable {
      home.packages = [cfg.package];
      home.file.".config/macchina/macchina.toml".source = (formats.toml {}).generate "macchina.toml" {
        interface = cfg.networkInterface;
        theme = "Dracula";
      };
      home.file.".config/macchina/themes/Dracula.toml".source = stdenv.mkDerivation rec {
        name = "macchina-dracula";
        version = substring 0 7 src.rev;
        src = fetchFromGitHub {
          owner = "di-effe";
          repo = "macchina-cli-themes";
          rev = "c1d7087b6999b36671d70ce2abf581ef1a9223d8";
          hash = "sha256-hlDafPLy15Tury345lYnW1sKBtLmxaahhsCJyL6SYcg=";
        };
        patchPhase = "${yq}/bin/tomlq --in-place --toml-output '.custom_ascii.path |= \"${
          fetchurl {
            url = "https://gist.githubusercontent.com/manpages/d68f2497cafb41b0c3d7/raw/fe1b5b77d48e7ff4443e96afff72bbe0c31dc5ee/Nix-logo.render";
            hash = "sha256-OfuhzjYtAaLrAztK3px/WRs1wlYY563ioJQRShmnTHY=";
          }
        }\"' Dracula.toml";
        installPhase = "cp Dracula.toml $out";
      };
    };
  };
}
