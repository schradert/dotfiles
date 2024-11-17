{
  # TODO find some good example config to see what the possibilities are
  # NOTE https://github.com/nix-community/home-manager/blob/master/modules/programs/waybar.nix
  canivete.deploy.nixos.homeModules.waybar = {config, ...}: {
    programs.waybar = {
      enable = config.dotfiles.graphical.hyprland.enable;
      systemd.enable = true;
    };
  };
}
