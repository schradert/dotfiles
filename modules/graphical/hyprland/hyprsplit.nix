{
  canivete.deploy.nixos.homeModules.hyprsplit = {config, lib, perSystem, ...}: let
    inherit (config.dotfiles.graphical) hyprland;
  in {
    options.dotfiles.graphical.hyprland.plugins.hyprsplit.enable = lib.mkEnableOption "Hyprsplit overview plugin" // {default = hyprland.enable;};
    config = lib.mkIf hyprland.plugins.hyprsplit.enable {
      wayland.windowManager.hyprland = {
        plugins = [perSystem.inputs'.hyprsplit.packages.hyprsplit];
        settings.plugin.hyprsplit.num_workspaces = 4;
        settings.bind = [
          "$mod+SHIFT, 1, split:swapactiveworkspaces, current 1"
          "$mod+SHIFT, 2, split:swapactiveworkspaces, current 2"
          "$mod+SHIFT, 3, split:swapactiveworkspaces, current 3"
          "$mod+SHIFT+CONTROL, =, split:grabroguewindows"
        ];
      };
    };
  };
}
