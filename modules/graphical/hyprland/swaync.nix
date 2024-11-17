{
  canivete.deploy.nixos.homeModules = {
    upstream-swaync = {config, lib, pkgs, ...}: let
      inherit (lib) getExe mkEnableOption mkIf mkOption mkPackageOption;
      inherit (config.dotfiles.programs.swaync) enable package settings;
      json = pkgs.formats.json {};
    in {
      options.dotfiles.programs.swaync = {
        enable = mkEnableOption "Sway notification center";
        package = mkPackageOption pkgs "swaynotificationcenter" {};
        settings = mkOption {
          inherit (json) type;
          description = "Sway notification center config.json contents";
          default = {};
        };
      };
      config = mkIf enable {
        home.packages = [package];
        xdg.configFile."swaync/config.json" = {
          onChange = "${getExe package} swaync-client --reload-config";
          source = json.generate "swaync.config.json" settings;
        };
      };
    };
    swaync = {config, ...}: {
      dotfiles.programs.swaync = {
        inherit (config.dotfiles.graphical.hyprland) enable;
        settings = {};
      };
    };
  };
}
