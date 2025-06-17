{
  # TODO is this better than hyprpaper? benefit of using hyprpaper if there are slow animations from HDD? what about both?
  # TODO should I also add waypaper support GUI?
  # TODO find some high quality public wallpaper images
  # TODO download these images through nix asset pinning and symlink to wallpaper directory
  # TODO schedule cycling through these images
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
    inherit (types) submodule path package listOf;
    inherit (config.dotfiles.services) swww;
  in {
    options.dotfiles.services.swww = {
      enable = mkEnableOption "swww wallpaper daemon for wayland" // {default = config.dotfiles.graphical.hyprland.enable;};
      package = mkPackageOption pkgs "swww" {};
      config = mkOption {
        default = {};
        type = submodule {
          options = {
            config_dir = mkOption {
              type = path;
              readOnly = true;
              default = "${config.xdg.configHome}/swww";
            };
            wallpapers_dir = mkOption {
              type = path;
              readOnly = true;
              default = "${swww.config.config_dir}/wallpapers";
            };
            wallpapers = mkOption {
              type = listOf package;
              default = [];
            };
          };
        };
      };
    };
    config = mkIf swww.enable {
      home.packages = [swww.package];
      # TODO host and mount wallpapers
      # xdg.configFile."swww/wallpapers".source = pkgs.linkFarm "wallpapers" swww.config.wallpapers;
      systemd.user.services.swww = {
        Unit.After = ["graphical-session-pre.target"];
        Unit.PartOf = ["graphical-session.target"];
        Service.ExecStart = "${swww.package}/bin/swww-daemon";
        Service.Restart = "on-failure";
        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
