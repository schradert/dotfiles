{inputs, ...}: let
  inherit (inputs.hyprland) nixosModules homeManagerModules overlays;
in {
  flake.overlays = {
    grim = inputs.grim-hyprland.overlays.default;
    hyprland = overlays.default;
    hyprland-plugins = inputs.hyprland-plugins.overlays.default;
    hyprpicker = inputs.hyprpicker.overlays.default;
  };
  dotfiles = {
    shared = {lib, ...}: {
      options.dotfiles.graphical.hyprland.enable = lib.mkEnableOption "Hyprland configuration";
    };
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [nixosModules.default];
      config = lib.mkIf config.dotfiles.graphical.hyprland.enable {
        services.displayManager.sddm.wayland.enable = true;
        environment.sessionVariables.NIXOS_OZONE_WL = "1";
        environment.systemPackages = with pkgs; [kitty xwaylandvideobridge];
        programs.hyprland.enable = true;
      };
    };
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [homeManagerModules.default];
      config = lib.mkIf config.dotfiles.graphical.hyprland.enable {
        # TODO why am I getting errors "style.scss expected a valid selector" and "js d.get is not a function"... probably should wait until it's more stable
        dotfiles.services.ags.enable = true;
        dotfiles.services.waybar.enable = false;
        dotfiles.programs.swaync.enable = true;
        # TODO research and activate the authentication agent
        # TODO create more common keybindings (e.g. logout, lock screen, terminal & other apps)
        # TODO spin up applications on startup
        # TODO research a good window management utility
        # TODO why do a lot of common shortcuts not work in emacs?
        # TODO do I actually HAVE to enable kitty? I can't even get it to work seemingly...
        # TODO why do I have weird lag issues randomly (mostly in brave)?
        # TODO use hyprwinwrap (kitty --config ... --class kitty-bg <script>) to run something as a background wallpaper...
        # TODO configure different language keyboards
        # NOTE https://github.com/coffebar/hyprland-per-window-layout
        # TODO should I do something with hot corners: https://git.sr.ht/~whynothugo/wlhc
        # TODO should I switch keyboard layouts with something like TApper: https://kbd-tapper.sourceforge.io/en.html
        # TODO should I also add hyprscroller
        home.packages = with pkgs; [
          libsForQt5.qt5.qtwayland
          qt6.qtwayland
          hyprpicker

          # Screenshots
          satty
          swappy
          grim
          wl-screenrec
          slurp

          # Clipboard
          wl-clipboard-rs # copy/paste
          wl-clip-persist # keeps clipboard awake after app close
          clipse # TUI manager
          cliphist # dmenu adapter
          # TODO can I also sync Clipboard
        ];
        home.sessionVariables.NIXOS_OZONE_WL = "1";
        programs.kitty.enable = true;
        wayland.windowManager.hyprland = {
          enable = true;
          # TODO do I need to enable autostart?
          systemd.enableXdgAutostart = false;
          systemd.variables = ["--all"];
          plugins = with pkgs.hyprlandPlugins; [
            hyprexpo
            hyprwinwrap
            # hyprbars
            # hyprtrails
            # borders-plus-plus
          ];
          settings = {
            "$mod" = "SUPER";
            animations.enabled = 1;
            animations.animation = [
              "windows, 1, 4, default, slide"
              "border, 1, 5, default"
              "fade, 1, 5, default"
              "workspaces, 1, 3, default"
            ];
            bind = [
              # TODO why don't variables like $terminal and $browser work?
              "$mod, grave, exec, brave"
              "$mod, return, exec, wezterm"
              "$mod+SHIFT, return, exec, doom run"

              "$mod, f, fullscreen, toggle"
              "$mod+CONTROL, f, togglefloating"

              "$mod+SHIFT, Tab, hyprexpo:expo, toggle"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
            decoration = {
              rounding = 8;
              active_opacity = 0.95;
              inactive_opacity = 0.83;
              blur.xray = true;
              shadow.color = "0x66000000";
              shadow.range = 4;
            };
            input.sensitivity = -1;
            input.touchpad.natural_scroll = true;
            general = {
              gaps_in = 6;
              gaps_out = 12;
              border_size = 4;
              "col.active_border" = "$general_active_border";
              "col.inactive_border" = "$general_inactive_border";
            };
            misc.disable_hyprland_logo = true;
            misc.disable_splash_rendering = true;
            plugin.hyprexpo = {
              columns = 2;
              gesture_positive = false;
            };
            source = ["~/.config/wpg/templates/hyprland.conf"];
            windowrulev2 = [
              "opacity 0.0 override, class:^(xwaylandvideobridge)$"
              "noanim, class:^(xwaylandvideobridge)$"
              "noinitialfocus, class:^(xwaylandvideobridge)$"
              "maxsize 1 1, class:^(xwaylandvideobridge)$"
              "noblur, class:^(xwaylandvideobridge)$"
              "nofocus, class:^(xwaylandvideobridge)$"
            ];
          };
        };
        # Use KDE file picker
        xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".source = (pkgs.formats.ini {}).generate "hyprland-portals.conf" {
          preferred.default = "hyprland;gtk";
          preferred."org.freedesktop.impl.portal.FileChooser" = "kde";
        };
        xdg.configFile."wpg/templates/hyprland.conf.base".text = ''
          $general_active_border = 0xff{active.strip}
          $general_inactive_border = 0xff{color0.strip}
        '';
      };
    };
  };
}
