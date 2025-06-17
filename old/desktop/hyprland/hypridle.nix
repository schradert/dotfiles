{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) getExe getExe';
    inherit (pkgs) brightnessctl hyprland hyprlock procps systemd;
    loginctl = getExe' systemd "loginctl";
    systemctl = getExe' systemd "systemctl";
    hyprctl = getExe' hyprland "hyprctl";
    pidof = getExe' procps "pidof";
    hyprlock' = getExe hyprlock;
    brightnessctl' = getExe brightnessctl;
  in {
    services.hypridle.enable = config.dotfiles.graphical.hyprland.enable;
    services.hypridle.settings = {
      general = {
        before_sleep_cmd = "${loginctl} lock-session";
        ignore_dbus_inhibit = true;
        # avoid starting multiple hyprlock instances
        lock_cmd = "${pidof} ${hyprlock'} || ${hyprlock'}";
        # avoid pressing keys twice to turn display on
        after_sleep_cmd = "${hyprctl} dispatch dpms on";
      };
      listener = [
        # TODO configure keyboard light device and add timeout for brightness (brightnessctl might help)
        # TODO change monitor brightness as well
        {
          timeout = 150;
          on-timeout = "${brightnessctl'} --save set 10";
          on-resume = "${brightnessctl'} --restore";
        }
        {
          timeout = 300;
          on-timeout = "${loginctl} lock-session";
        }
        {
          timeout = 330;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "${systemctl} suspend";
        }
      ];
    };
  };
}
