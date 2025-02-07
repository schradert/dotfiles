{inputs, ...}: let
  inherit (inputs.hyprland) nixosModules homeManagerModules overlays;
in {
  flake.overlays = {
    hyprland = overlays.default;
    hyprland-plugins = inputs.hyprland-plugins.overlays.default;
  };
  canivete.deploy.nixos.modules.hyprland = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    inherit (pkgs) hyprlandPlugins hyprpicker kitty libsForQt5 qt6 systemd xwaylandvideobridge;
  in {
    imports = [nixosModules.default];
    options.dotfiles.graphical.hyprland.enable = mkEnableOption "Hyprland configuration";
    config = mkIf config.dotfiles.graphical.hyprland.enable {
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
        # TODO use hyprwinwrap (kitty --config ... --class kitty-bg <script>) to run something as a background wallpaper...
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
            hyprexpo
            hyprwinwrap
            # hyprbars
            # hyprtrails
            # borders-plus-plus
          ];
          settings = {
            "$mod" = "SUPER";
            bind = [
              # TODO why don't variables like $terminal and $browser work?
              "$mod, grave, exec, brave"
              "$mod, return, exec, wezterm"
              "$mod+SHIFT, return, exec, doom run"

              "$mod, f, fullscreen, toggle"
              "$mod+CONTROL, f, togglefloating"

              "$mod, F1, workspace, 01"
              "$mod, F2, workspace, 02"
              "$mod, F3, workspace, 03"
              "$mod, F4, workspace, 04"
              "$mod, F5, workspace, 05"
              "$mod, F6, workspace, 06"
              "$mod, F7, workspace, 07"
              "$mod, F8, workspace, 08"
              "$mod, F9, workspace, 09"
              "$mod, F10, workspace, 10"
              "$mod, F11, workspace, 11"
              "$mod, F12, workspace, 12"

              "$mod+SHIFT, Tab, hyprexpo:expo, toggle"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
            plugin.hyprexpo = {
              columns = 2;
              gesture_positive = false;
            };
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
