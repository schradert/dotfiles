{
  dotfiles.home-manager = {
    config,
    lib,
    perSystem,
    ...
  }: let
    inherit (config.dotfiles.graphical) hyprland;
  in {
    options.dotfiles.graphical.hyprland.plugins.hyprspace.enable = lib.mkEnableOption "Hyprspace overview plugin" // {default = hyprland.enable;};
    config = lib.mkIf hyprland.plugins.hyprspace.enable {
      wayland.windowManager.hyprland = {
        plugins = [perSystem.inputs'.hyprspace.packages.Hyprspace];
        settings.bind = ["$mod, Tab, overview:toggle, all"];
        settings.plugin.overview = {};
      };
    };
  };
}
