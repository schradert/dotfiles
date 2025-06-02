{
  # TODO find some good example config to see what the possibilities are
  # NOTE https://github.com/nix-community/home-manager/blob/master/modules/programs/waybar.nix
  dotfiles.home-manager = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.services.waybar.enable = lib.mkEnableOption "Waybar status bar" // {default = config.dotfiles.graphical.hyprland.enable;};
    config = lib.mkIf config.dotfiles.services.waybar.enable {
      programs.waybar = {
        inherit (config.dotfiles.graphical.hyprland) enable;
        systemd.enable = true;
        settings.top = {
          layer = "top";
          position = "left";
          margin = "5 2 5 0";
          reload_style_on_change = true;
          modules-left = ["hyprland/workspaces" "custom/music"];
          modules-center = ["hyprland/window"];
          modules-right = ["pulseaudio" "clock"];
          "hyprland/submap".format = "<b>{}</b>";
          "hyprland/workspaces".all-outputs = false;
          "custom/music" = {
          };
        };
      };
    };
  };
}
