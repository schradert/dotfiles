{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.profiles.client.plasma.enable = lib.mkEnableOption "Plasma KDE Desktop Manager";
    config = lib.mkIf config.dotfiles.profiles.client.plasma.enable {
      assertions = lib.toList {
        assertion = config.dotfiles.profiles.client.enable;
        message = "Plasma is for clients";
      };
      home-manager.sharedModules = [
        {
          # Seems like this file always conflicts in a Plasma session...
          # NOTE https://github.com/nix-community/home-manager/issues/6188#issuecomment-2749859294
          gtk.gtk2.force = true;
          # TODO why isn't the builtin Plasma 6 notification daemon not working?
          services.swaync.enable = true;
        }
      ];
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.settings.General.DisplayServer = "wayland";
      services.xserver.enable = true;
    };
  };
}
