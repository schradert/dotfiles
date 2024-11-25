{inputs, ...}: let
  inherit (inputs.hyprland) nixosModules homeManagerModules overlays;
in {
  flake.overlays.hyprland = overlays.default;
  canivete.deploy.nixos.modules.hyprland = {config, lib, pkgs, ...}: let
    inherit (lib) flatten mkEnableOption mkIf toList;
    inherit (pkgs) hyprlandPlugins kitty libsForQt5 qt6 systemd;
  in {
    imports = [nixosModules.default];
    options.dotfiles.graphical.hyprland.enable = mkEnableOption "Hyprland configuration";
    config = mkIf config.dotfiles.graphical.hyprland.enable {
      nix.settings.substituters = ["https://hyprland.cachix.org"];
      nix.settings.trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      services.displayManager.sddm.wayland.enable = true;
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = [kitty];
      programs.hyprland.enable = true;
      home-manager.sharedModules = toList {
        imports = [homeManagerModules.default];
        # TODO research and activate the authentication agent
        # TODO create more common keybindings (e.g. logout, lock screen, terminal & other apps)
        # TODO spin up applications on startup
        # TODO research a good window management utility
        # TODO why do a lot of common shortcuts not work in emacs?
        # TODO do I actually HAVE to enable kitty? I can't even get it to work seemingly...
        # TODO why do I have weird lag issues randomly (mostly in brave)?
        home.packages = [
          libsForQt5.qt5.qtwayland
          qt6.qtwayland
        ];
        home.sessionVariables.NIXOS_OZONE_WL = "1";
        programs.kitty.enable = true;
        wayland.windowManager.hyprland = {
          enable = true;
          # TODO do I need to enable autostart?
          systemd.enableXdgAutostart = false;
          systemd.variables = ["--all"];
          plugins = with hyprlandPlugins; [
            # hyprbars
            # hyprexpo
            # hyprtrails
            # hyprwinwrap
            # borders-plus-plus
          ];
          settings = {
            "$mod" = "SUPER";
            bind = [
              # TODO why don't variables like $terminal and $browser work?
              "$mod, grave, exec, brave"
              "$mod, return, exec, wezterm"
              "$mod+SHIFT, return, exec, doom run"

              "$mod, f, fullscreen, 1"
              "$mod+SHIFT, f, fullscreen, 0"

              "$mod, Tab, overview:toggle"
              "$mod+SHIFT, Tab, togglefloating"

              "$mod, 1, workspace, 01"
              "$mod, 2, workspace, 02"
              "$mod, 3, workspace, 03"
              "$mod, 4, workspace, 04"
              "$mod, 5, workspace, 05"
              "$mod, 6, workspace, 06"
              "$mod, 7, workspace, 07"
              "$mod, 8, workspace, 08"
              "$mod, 9, workspace, 09"
              "$mod, 0, workspace, 10"
              "$mod, F1, workspace, 11"
              "$mod, F2, workspace, 12"
              "$mod, F3, workspace, 13"
              "$mod, F4, workspace, 14"
              "$mod, F5, workspace, 15"
              "$mod, F6, workspace, 16"
              "$mod, F7, workspace, 17"
              "$mod, F8, workspace, 18"
              "$mod, F9, workspace, 19"
              "$mod, F10, workspace, 20"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
          };
        };
        # Use KDE file picker
        xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".source = (pkgs.formats.ini {}).generate "hyprland-portals.conf" {
          preferred.default = "hyprland;gtk";
          preferred."org.freedesktop.impl.portal.FileChooser" = "kde";
        };
      };
    };
  };
}
