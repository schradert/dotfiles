{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.graphical.hyprland.plugins) hyprshade;
    inherit (lib) mkIf mkEnableOption mkPackageOption mkOption getExe getExe';
    toml = pkgs.formats.toml {};
  in {
    options.dotfiles.graphical.hyprland.plugins.hyprshade = {
      enable = mkEnableOption "hyprshade shader decorations";
      package = mkPackageOption pkgs "hyprshade" {};
      config = mkOption {
        inherit (toml) type;
        default = {};
      };
    };
    config = mkIf hyprshade.enable {
      home.activation.hyprshade = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${getExe hyprshade.package} install
        ${getExe' pkgs.systemd "systemctl"} --user enable --now hyprshade.timer
      '';
      home.packages = [hyprshade.package];
      dotfiles.graphical.hyprland.plugins.hyprshade.config.shaders = [
        {
          name = "vibrance";
          default = true;
        }
        {
          name = "blue-light-filter";
          start_time = "18:00:00";
          end_time = "06:00:00";
        }
        {
          name = "color-filter";
          config.type = "red-green";
          config.strength = 1.0;
        }
      ];
      xdg.configFile."hyprshade/config.toml" = mkIf (hyprshade.config != {}) {source = toml.generate "hyprshade.config.toml" hyprshade.config;};
      wayland.windowManager.hyprland.settings.exec = ["${getExe hyprshade.package} auto"];
    };
  };
}
