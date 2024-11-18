{inputs, ...}: let
  inherit (inputs.hyprland) nixosModules homeManagerModules overlays;
in {
  flake.overlays.hyprland = overlays.default;
  canivete.deploy.nixos.modules.hyprland = {config, lib, pkgs, ...}: let
    inherit (lib) flatten genList getExe getExe' mkEnableOption mkIf mkMerge pipe toList;
    inherit (pkgs) hyprlandPlugins hyprpolkitagent kitty libsForQt5 qt6 systemd;
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
            # hy3
            # hyprbars
            # hyprexpo
            # hyprtrails
            # hyprwinwrap
            # borders-plus-plus
          ];
          settings = {
            "$mod" = "SUPER";
            exec-once = ["${getExe' systemd "systemctl"} --user start ${getExe hyprpolkitagent}"];
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
