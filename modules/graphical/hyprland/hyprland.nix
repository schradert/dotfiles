{inputs, ...}: let
  inherit (inputs.hyprland) nixosModules homeManagerModules overlays;
in {
  flake.overlays.hyprland = overlays.default;
  canivete.deploy.nixos.modules.hyprland = {config, lib, pkgs, ...}: let
    inherit (lib) flatten genList getExe mkEnableOption mkIf mkMerge pipe toList;
    inherit (pkgs) hyprlandPlugins kitty libsForQt5 qt6;
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
        # TODO what is the polkit auth agent helping with?
        # TODO why do I have weird lag issues?
        home.packages = [
          libsForQt5.polkit-kde-agent
          libsForQt5.qt5.qtwayland
          qt6.qtwayland
        ];
        home.sessionVariables.NIXOS_OZONE_WL = "1";
        programs.kitty.enable = true;
        wayland.windowManager.hyprland = {
          enable = true;
          # TODO do I need to enable autostart?
          systemd.enableXdgAutostart = false;
          # TODO will applications share data properly if I pass all variables?
          # systemd.variables = ["--all"];
          plugins = with hyprlandPlugins; [
            # hy3
            # hyprbars
            # hyprexpo
            # hyprtrails
            # hyprwinwrap
            # borders-plus-plus
          ];
          settings = {
            "$mod" = "SUPER";
            exec-once = [
              # TODO what is this accomplishing? Do I need to add DISPLAY and HYPRLAND_INSTANCE_SIGNATURE?
              "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
              "polkit-kde-authentication-agent-1"
            ];
            monitor = [
              "DVI-I-1, 3840x2160@60.00, 0x0, 1, transform, 1"
              "DVI-I-2, 3840x2160@60.00, 2160x400, 1"
              "eDP-1, 1920x1080@60.02, 6000x800, 1"
            ];
            bind = mkMerge [
              [
                # TODO why doesn't variables like $terminal and $browser work?
                "$mod, B, exec, brave"
                "$mod, T, exec, wezterm"
                # TODO how can I test that this works?
                ", Print, exec, grimblast copy area"
              ]
              # TODO why doesn't this work? keybinding conflicts? should I even keep this?
              # Workspace management shortcuts
              (pipe 9 [
                (genList (i: [
                  "$mod, code:1${toString i}, workspace, ${toString (i+1)}"
                  "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString (i+1)}"
                ]))
               flatten
              ])
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
