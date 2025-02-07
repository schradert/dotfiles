{
  canivete.deploy.nixos.homeModules.hyprpolkitagent = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.graphical.hyprland.enable {
      wayland.windowManager.hyprland.settings.exec-once = ["${lib.getExe' pkgs.systemd "systemctl"} --user start hyprpolkitagent"];
      xdg.configFile."systemd/user/hyprpolkitagent.service".source = pkgs.hyprpolkitagent + "/lib/systemd/user/hyprpolkitagent.service";
    };
  };
}
