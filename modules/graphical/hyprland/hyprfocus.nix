{
  canivete.deploy.nixos.homeModules.hyprfocus = {
    config,
    lib,
    perSystem,
    ...
  }: let
    inherit (config.dotfiles.graphical) hyprland;
  in {
    options.dotfiles.graphical.hyprland.plugins.hyprfocus.enable = lib.mkEnableOption "Hyprland's hyprfocus animation plugin" // {default = hyprland.enable;};
    config = lib.mkIf hyprland.plugins.hyprfocus.enable {
      wayland.windowManager.hyprland = {
        plugins = [perSystem.inputs'.hyprfocus.packages.hyprfocus];
        settings.bind = ["$mod+SHIFT, SPACE, animatefocused"];
        settings.plugin.hyprfocus = {
          enabled = "yes";
          animate_floating = "yes";
          animate_workspacechange = "yes";
          focus_animation = "shrink";
          shrink = {
            shrink_percentage = 0.99;
            in_bezier = "realsmoooth";
            in_speed = 1;
            out_bezier = "realsmooth";
            out_speed = 2;
          };
        };
      };
    };
  };
}
