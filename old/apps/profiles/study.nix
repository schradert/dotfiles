{
  flake.overlays.wordnet = _: prev: {
    # TODO create a TUI to navigate this better
    # TODO how can I create a TUI with open-english-wordnet and the globalwordnet? (OMW)
    wordnet = prev.wordnet.overrideAttrs (old: {
      patchPhase = old.patchPhase + "\nsed '132s/^/int /' -i src/wn.c\n";
    });
  };
  dotfiles.darwin = {
    config,
    lib,
    ...
  }: {
    homebrew.casks = lib.mkIf config.dotfiles.profiles.workstation.enable [
      "anki"
    ];
  };
  dotfiles.home-manager = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf mkMerge pipe splitString;
    # NOTE list possible layouts and variants with `cat /etc/X11/xkb/rules/base.lst`
    layouts = "us,ara,br,cn,fi,fr,de,jp,kr,ru,latam,tr";
    cmd = canivete.prefix "hyprctl switchxkblayout corsair-corsair-k63-wireless-usb-receiver-keyboard ";
  in {
    config = mkIf config.dotfiles.profiles.workstation.enable (mkMerge [
      {
        dotfiles.programs.emacs.orgFiles = [./languages.org];
        home.packages = with pkgs;
          mkMerge [
            (mkIf stdenv.hostPlatform.isLinux [anki])
            [
              fend
              kalker
              numbat
              markmap
              wordnet
              duden
              urban-cli
            ]
          ];
      }
      (mkIf config.wayland.windowManager.hyprland.enable (mkMerge [
        {
          wayland.windowManager.hyprland.settings = {
            input.kb_layout = layouts;
            bind = ["$mod, F11, exec, ${cmd "next"}"];
          };
        }
        (mkIf config.programs.walker.enable {
          programs.walker.config.plugins = [
            {
              name = "xkb";
              placeholder = "Keyboard Layouts";
              switcher_only = true;
              recalculate_score = true;
              show_icon_when_single = true;
              entries = pipe layouts [
                (splitString ",")
                (map (layout: {
                  label = layout;
                  exec = cmd layout;
                }))
              ];
            }
          ];
        })
      ]))
    ]);
  };
}
