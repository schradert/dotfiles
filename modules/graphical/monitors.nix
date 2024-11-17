{
  # TODO figure out a proper arrangement of monitors to allow synchronized brightness control
  # NOTE DisplayLink seems to not work well with the DDC/CI standard, even though HDMI/USB is hinted to work
  canivete.deploy.nixos = {
    modules.monitors = {config, flake, lib, pkgs, ...}: {
      options.dotfiles.graphical.monitors = lib.mkEnableOption "Graphical monitor setup at home";
      config = lib.mkIf config.dotfiles.graphical.monitors {
        boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
        boot.kernelModules = ["ddcci_backlight"];
        environment.systemPackages = with pkgs; [brightnessctl ddcutil];
        hardware.acpilight.enable = true;
        hardware.brillo.enable = true;
        hardware.i2c.enable = config.dotfiles.graphical.monitors;
        programs.light.enable = true;
        programs.light.brightnessKeys.enable = true;
        services.ddccontrol.enable = true;
        services.redshift.enable = true;
        users.users.${flake.config.canivete.people.me}.extraGroups = ["i2c"];
      };
    };
    homeModules.monitors = {config, lib, ...}: {
      config = lib.mkIf config.dotfiles.graphical.monitors {
        wayland.windowManager.hyprland.settings.monitor = [
          "DVI-I-1, 3840x2160@60.00, 0x0, 1, transform, 1"
          "DVI-I-2, 3840x2160@60.00, 2160x400, 1"
          # TODO will this work generally?
          "eDP-1, 1920x1080@60.02, 6000x800, 1"
        ];
      };
    };
  };
}
