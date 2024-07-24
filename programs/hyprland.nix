{nix, ...}:
with nix; {
  flake.homeModules.hyprland = {
    config,
    pkgs,
    ...
  }: {
    config = mkIf (pkgs.stdenv.isLinux && config.dotfiles.graphical.enable) (mkMerge [
      {
        home.packages = [pkgs.swaynotificationcenter];
        xdg.configFile."swaync/config.json" = {
          onChange = "${getExe pkgs.swaynotificationcenter} swaync-client --reload-config";
          text = builtins.toJSON {};
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
        programs.waybar = {
          enable = true;
          systemd.enable = true;
        };
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
        home.packages = [pkgs.swww];
        systemd.user.services.swww = {
          Unit.After = ["graphical-session-pre.target"];
          Unit.PartOf = ["graphical-session.target"];
          Service.ExecStart = "${pkgs.swww}/bin/swww-daemon";
        };
      }
      {
        # TODO research and activate the authentication agent
        # TODO create more common keybindings (e.g. logout, lock screen, terminal & other apps)
        # TODO spin up applications on startup
        # TODO research a good window management utility
        home.packages = with pkgs; [
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
    ]);
  };
  flake.nixosModules.hyprland = {config, ...}: {
    config = mkIf config.dotfiles.graphical.enable {
      services.displayManager.sddm.wayland.enable = true;
      programs.hyprland.enable = true;
      programs.hyprland.xwayland.enable = true;
    };
  };
}
