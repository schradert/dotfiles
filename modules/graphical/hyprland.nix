{
  canivete.deploy.nixos.modules.hyprland = {config, lib, pkgs, ...}: let
    inherit (lib) getExe mkEnableOption mkIf mkMerge toJSON;
    inherit (pkgs) libsForQt5 qt6 swww swaynotificationcenter;
  in {
    options.dotfiles.graphical.wayland.enable = mkEnableOption "Wayland configuration";
    config = mkIf config.dotfiles.graphical.wayland.enable {
      services.displayManager.sddm.wayland.enable = true;
      programs.hyprland.enable = true;
      programs.hyprland.xwayland.enable = true;
      home-manager.sharedModules = [
        {
          home.packages = [swaynotificationcenter];
          xdg.configFile."swaync/config.json" = {
            onChange = "${getExe swaynotificationcenter} swaync-client --reload-config";
            text = toJSON {};
          };
        }
        {
          # TODO investigate if this can start up faster
          # TODO find good example config online
          programs.rofi.enable = true;
          wayland.windowManager.hyprland.settings.bind = ["$mainMod, S, exec, rofi -show drun -show-icons"];
        }
        {
          # TODO find some good example config to see what the possibilities are
          programs.waybar.enable = true;
          programs.waybar.systemd.enable = true;
        }
        {
          # TODO find good example config to make use of this
          # TODO tweak the styling to look just right
          programs.wlogout.enable = true;
        }
        {
          # TODO find some high quality public wallpaper images
          # TODO download these images through nix asset pinning and symlink to wallpaper directory
          # TODO schedule cycling through these images
          home.packages = [swww];
          systemd.user.services.swww = {
            Unit.After = ["graphical-session-pre.target"];
            Unit.PartOf = ["graphical-session.target"];
            Service.ExecStart = "${swww}/bin/swww-daemon";
          };
        }
        {
          # TODO research and activate the authentication agent
          # TODO create more common keybindings (e.g. logout, lock screen, terminal & other apps)
          # TODO spin up applications on startup
          # TODO research a good window management utility
          home.packages = [
            libsForQt5.polkit-kde-agent
            libsForQt5.qt5.qtwayland
            qt6.qtwayland
          ];
          wayland.windowManager.hyprland = {
            enable = true;
            settings = {
              "$mainMod" = "SUPER";
              exec-once = ["dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" "polkit-kde-authentication-agent-1"];
              # "$terminal" = "wezterm";
              # bind = ["$mainMod, SPC, exec, $terminal"];
            };
          };
        }
      ];
    };
  };
}
