{
  canivete.deploy.nixos.homeModules.hy3 = {config, lib, perSystem, ...}: let
    inherit (config.dotfiles.graphical) hyprland;
  in {
    options.dotfiles.graphical.hyprland.plugins.hy3.enable = lib.mkEnableOption "Hy3 Hyprland plugin" // {default = hyprland.enable;};
    config = lib.mkIf hyprland.plugins.hy3.enable {
      # TODO do I need to handle dynamic key remapping in wayland https://github.com/xremap/xremap
      wayland.windowManager.hyprland = {
        plugins = [perSystem.inputs'.hy3.packages.hy3];
        settings.general.layout = "hy3";
        settings.bindn = [
          ", mouse:272, hy3:focustab, mouse"
          ", mouse_down, hy3:focustab, l, require_hovered"
          ", mouse_up, hy3:focustab, r, require_hovered"
        ];
        settings.bind = [
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
          "$mod, left, hy3:movefocus, l"
          "$mod, down, hy3:movefocus, d"
          "$mod, up, hy3:movefocus, u"
          "$mod, right, hy3:movefocus, r"

          "$mod+CONTROL, h, hy3:movefocus, l, visible, nowarp"
          "$mod+CONTROL, j, hy3:movefocus, d, visible, nowarp"
          "$mod+CONTROL, k, hy3:movefocus, u, visible, nowarp"
          "$mod+CONTROL, l, hy3:movefocus, r, visible, nowarp"
          "$mod+CONTROL, left, hy3:movefocus, l, visible, nowarp"
          "$mod+CONTROL, down, hy3:movefocus, d, visible, nowarp"
          "$mod+CONTROL, up, hy3:movefocus, u, visible, nowarp"
          "$mod+CONTROL, right, hy3:movefocus, r, visible, nowarp"

          "$mod+SHIFT, h, hy3:movewindow, l, once"
          "$mod+SHIFT, j, hy3:movewindow, d, once"
          "$mod+SHIFT, k, hy3:movewindow, u, once"
          "$mod+SHIFT, l, hy3:movewindow, r, once"
          "$mod+SHIFT, left, hy3:movewindow, l, once"
          "$mod+SHIFT, down, hy3:movewindow, d, once"
          "$mod+SHIFT, up, hy3:movewindow, u, once"
          "$mod+SHIFT, right, hy3:movewindow, r, once"

          "$mod+CONTROL+SHIFT, h, hy3:movewindow, l, once, visible"
          "$mod+CONTROL+SHIFT, j, hy3:movewindow, d, once, visible"
          "$mod+CONTROL+SHIFT, k, hy3:movewindow, u, once, visible"
          "$mod+CONTROL+SHIFT, l, hy3:movewindow, r, once, visible"
          "$mod+CONTROL+SHIFT, left, hy3:movewindow, l, once, visible"
          "$mod+CONTROL+SHIFT, down, hy3:movewindow, d, once, visible"
          "$mod+CONTROL+SHIFT, up, hy3:movewindow, u, once, visible"
          "$mod+CONTROL+SHIFT, right, hy3:movewindow, r, once, visible"

          "$mod+SHIFT, 1, hy3:movetoworkspace, 01"
          "$mod+SHIFT, 2, hy3:movetoworkspace, 02"
          "$mod+SHIFT, 3, hy3:movetoworkspace, 03"
          "$mod+SHIFT, 4, hy3:movetoworkspace, 04"
          "$mod+SHIFT, 5, hy3:movetoworkspace, 05"
          "$mod+SHIFT, 6, hy3:movetoworkspace, 06"
          "$mod+SHIFT, 7, hy3:movetoworkspace, 07"
          "$mod+SHIFT, 8, hy3:movetoworkspace, 08"
          "$mod+SHIFT, 9, hy3:movetoworkspace, 09"
          "$mod+SHIFT, 0, hy3:movetoworkspace, 10"
          "$mod+SHIFT, F1, hy3:movetoworkspace, 11"
          "$mod+SHIFT, F2, hy3:movetoworkspace, 12"
          "$mod+SHIFT, F3, hy3:movetoworkspace, 13"
          "$mod+SHIFT, F4, hy3:movetoworkspace, 14"
          "$mod+SHIFT, F5, hy3:movetoworkspace, 15"
          "$mod+SHIFT, F6, hy3:movetoworkspace, 16"
          "$mod+SHIFT, F7, hy3:movetoworkspace, 17"
          "$mod+SHIFT, F8, hy3:movetoworkspace, 18"
          "$mod+SHIFT, F9, hy3:movetoworkspace, 19"
          "$mod+SHIFT, F10, hy3:movetoworkspace, 20"

          "$mod+CONTROL, 1, hy3:focustab, index, 01"
          "$mod+CONTROL, 2, hy3:focustab, index, 02"
          "$mod+CONTROL, 3, hy3:focustab, index, 03"
          "$mod+CONTROL, 4, hy3:focustab, index, 04"
          "$mod+CONTROL, 5, hy3:focustab, index, 05"
          "$mod+CONTROL, 6, hy3:focustab, index, 06"
          "$mod+CONTROL, 7, hy3:focustab, index, 07"
          "$mod+CONTROL, 8, hy3:focustab, index, 08"
          "$mod+CONTROL, 9, hy3:focustab, index, 09"
          "$mod+CONTROL, 0, hy3:focustab, index, 10"
        ];
      };
    };
  };
}
