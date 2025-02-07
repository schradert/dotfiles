{
  # TODO configure backups: https://pot-app.com/docs/config/backup.html
  # TODO run as a service?
  # TODO walker commands
  canivete.deploy.system.homeModules.pot = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.services) pot;
  in {
    options.dotfiles.services.pot = {
      enable = lib.mkEnableOption "pot translation app";
      package = lib.mkPackageOption pkgs "pot" {};
    };
    config = lib.mkIf pot.enable {
      home.packages = [pot.package];
      wayland.windowManager.hyprland.settings.windowrulev2 = [
        "float, class:(pot), title:(Translator|OCR|PopClip|Screenshot Translate)"
        "move cursor 0 0, class:(pot), title:(Translator|PopClip|Screenshot Translate)"
      ];
    };
  };
}
