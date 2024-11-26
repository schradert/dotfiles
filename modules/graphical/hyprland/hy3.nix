{
  canivete.deploy.nixos.homeModules.hy3 = {config, lib, perSystem, ...}: let
    inherit (config.dotfiles.graphical) hyprland;
  in {
    options.dotfiles.graphical.hyprland.plugins.hy3.enable = lib.mkEnableOption "Hy3 Hyprland plugin" // {default = hyprland.enable;};
    config = lib.mkIf hyprland.plugins.hy3.enable {
      # TODO configure plugin for autotiling
      # TODO do I need to handle dynamic key remapping in wayland https://github.com/xremap/xremap
      wayland.windowManager.hyprland = {
        plugins = [perSystem.inputs'.hy3.packages.hy3];
        settings = {
          general.layout = "hy3";
          plugin.hy3 = {
            tabs.text_center = true;
            # TODO colors from theme
            autotile.enable = true;
          };
          bindn = [
            ", mouse:272, hy3:focustab, mouse"
            ", mouse_down, hy3:focustab, l, require_hovered"
            ", mouse_up, hy3:focustab, r, require_hovered"
          ];
          bind = [
            "$mod, q, hy3:warpcursor"
            "$mod+SHIFT, q, hy3:killactive"

            "$mod, a, hy3:changefocus, raise"
            "$mod+SHIFT, a, hy3:changefocus, lower"

            "$mod, e, hy3:expand, expand"
            "$mod+SHIFT, e, hy3:expand, base"

            "$mod, d, hy3:makegroup, h"
            "$mod, s, hy3:makegroup, v"
            "$mod, z, hy3:makegroup, tab"
            "$mod, r, hy3:changegroup, opposite"

            "$mod, h, hy3:movefocus, l"
            "$mod, j, hy3:movefocus, d"
            "$mod, k, hy3:movefocus, u"
            "$mod, l, hy3:movefocus, r"

            "$mod+CONTROL, h, hy3:movefocus, l, visible"
            "$mod+CONTROL, j, hy3:movefocus, d, visible"
            "$mod+CONTROL, k, hy3:movefocus, u, visible"
            "$mod+CONTROL, l, hy3:movefocus, r, visible"

            "$mod+SHIFT, F1, hy3:movetoworkspace, 01"
            "$mod+SHIFT, F2, hy3:movetoworkspace, 02"
            "$mod+SHIFT, F3, hy3:movetoworkspace, 03"
            "$mod+SHIFT, F4, hy3:movetoworkspace, 04"
            "$mod+SHIFT, F5, hy3:movetoworkspace, 05"
            "$mod+SHIFT, F6, hy3:movetoworkspace, 06"
            "$mod+SHIFT, F7, hy3:movetoworkspace, 07"
            "$mod+SHIFT, F8, hy3:movetoworkspace, 08"
            "$mod+SHIFT, F9, hy3:movetoworkspace, 09"
            "$mod+SHIFT, F10, hy3:movetoworkspace, 10"
            "$mod+SHIFT, F11, hy3:movetoworkspace, 11"
            "$mod+SHIFT, F10, hy3:movetoworkspace, 12"

            "$mod+SHIFT, h, hy3:movewindow, l, once"
            "$mod+SHIFT, j, hy3:movewindow, d, once"
            "$mod+SHIFT, k, hy3:movewindow, u, once"
            "$mod+SHIFT, l, hy3:movewindow, r, once"

            "$mod+SHIFT+CONTROL, h, hy3:movewindow, l, once, visible"
            "$mod+SHIFT+CONTROL, j, hy3:movewindow, d, once, visible"
            "$mod+SHIFT+CONTROL, k, hy3:movewindow, u, once, visible"
            "$mod+SHIFT+CONTROL, l, hy3:movewindow, r, once, visible"
          ];
        };
      };
    };
  };
}
