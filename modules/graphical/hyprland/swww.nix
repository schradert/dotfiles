{
  canivete.deploy.nixos.homeModules = {
    upstream-swww = {
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
        enable = mkEnableOption "swww wallpaper daemon for wayland";
        package = mkPackageOption pkgs "swww" {};
      };
      config = mkIf swww.enable {
        home.packages = [swww.package];
        systemd.user.services.swww = {
          Unit.After = ["graphical-session-pre.target"];
          Unit.PartOf = ["graphical-session.target"];
          Service.ExecStart = "${swww.package}/bin/swww-daemon";
        };
      };
    };
    swww = {config, ...}: {
      # TODO is this better than hyprpaper? benefit of using hyprpaper if there are slow animations from HDD? what about both?
      # TODO should I also add waypaper support GUI?
      # TODO find some high quality public wallpaper images
      # TODO download these images through nix asset pinning and symlink to wallpaper directory
      # TODO schedule cycling through these images
      dotfiles.services.swww.enable = config.dotfiles.graphical.hyprland.enable;
    };
  };
}
