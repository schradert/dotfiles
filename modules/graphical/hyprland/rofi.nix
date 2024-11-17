{
  # TODO investigate if this can start up faster
  # TODO find good example config online
  # NOTE https://github.com/nix-community/home-manager/blob/master/modules/programs/rofi.nix
  canivete.deploy.nixos.homeModules.rofi = {config, ...}: {
    programs.rofi.enable = config.dotfiles.graphical.hyprland.enable;
    wayland.windowManager.hyprland.settings.bind = ["$mod, SPC, exec, rofi -show drun -show-icons"];
  };
}
