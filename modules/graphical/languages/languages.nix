{
  canivete.deploy.system.homeModules.languages = {
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
    config = mkIf config.dotfiles.workstation.enable (mkMerge [
      {
        dotfiles.programs.emacs.orgFiles = [./languages.org];
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
