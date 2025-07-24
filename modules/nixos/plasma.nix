{
  dotfiles.nixos = {
    config,
    lib,
    pkgs,
    platform,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    ini = pkgs.formats.ini {};
  in {
    options.dotfiles.profiles.client.plasma.enable = mkEnableOption "Plasma KDE Desktop Manager";
    config = mkIf config.dotfiles.profiles.client.plasma.enable (mkMerge [
      {
        assertions = toList {
          assertion = config.dotfiles.profiles.client.enable;
          message = "Plasma is for clients";
        };
        home-manager.sharedModules = [
          {
            # Seems like this file always conflicts in a Plasma session...
            # NOTE https://github.com/nix-community/home-manager/issues/6188#issuecomment-2749859294
            gtk.gtk2.force = true;
            # TODO why isn't the builtin Plasma 6 notification daemon working?
            services.swaync.enable = true;
          }
        ];
        services.desktopManager.plasma6.enable = true;
        services.displayManager.sddm.enable = true;
        services.displayManager.sddm.settings.General.DisplayServer = "wayland";
        services.xserver.enable = true;
      }
      (mkIf (platform ? mobile) {
        services.displayManager.defaultSession = "plasma-mobile";
        hardware.sensor.iio.enable = true;
        services.displayManager.sessionPackages = [pkgs.kdePackages.plasma-mobile];
        environment.etc."xdg/kdeglobals".source = ini.generate "kdeglobals" {
          KDE.LookAndFeelPackage = "org.kde.plasma.phone";
        };
        environment.etc."xdg/kwinrc".source = ini.generate "kwinrc" {
          Wayland."InputMethod[$e]" = "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
          Wayland.VirtualKeyboardEnabled = "true";
          "org.kde.kdecoration2".NoPlugin = "true";
        };
        environment.systemPackages = with pkgs.kdePackages; [
          plasma-mobile
          plasma-nano

          # Plasma Mobile Gear
          alligator
          angelfish
          audiotube
          calindori
          kalk
          kasts
          kclock
          keysmith
          koko
          krecorder
          ktrip
          kweather
          plasma-dialer
          spacebar

          # Why are these not in kdePackages?
          pkgs.libsForQt5.plasma-phonebook
          pkgs.libsForQt5.plasma-phonebook

          pkgs.maliit-framework
          pkgs.maliit-keyboard
        ];
      })
    ]);
  };
}
