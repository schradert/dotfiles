{
  # TODO is hyprscratch in improvement over pyprland's scratchpads?
  # NOTE https://github.com/sashetophizika/hyprscratch
  # TODO create way more scratchpads and shortcuts and system notifier sources
  canivete.deploy.nixos.homeModules.pyprland = {
    config,
    lib,
    pkgs,
    perSystem,
    ...
  }: let
    inherit (config.dotfiles.graphical.hyprland) pyprland;
    inherit (lib) mkEnableOption mkIf mkOption mkPackageOption getExe mkMerge mapAttrs mergeAttrs;
    toml = pkgs.formats.toml {};
  in {
    options.dotfiles.graphical.hyprland.pyprland = {
      enable = mkEnableOption "pyprland hyprland plugins";
      package = mkPackageOption perSystem.inputs'.pyprland.packages "pyprland" {};
      settings = mkOption {
        inherit (toml) type;
        default = {};
      };
    };
    config = mkIf pyprland.enable {
      dotfiles.graphical.hyprland.pyprland.settings = {
        pyprland.plugins = ["expose" "fetch_client_menu" "scratchpads" "shortcuts_menu" "system_notifier"];
        expose.include_special = true;
        scratchpads = mkMerge [
          {
            all.class = "scratchpad";
            all.unfocus = "hide";
            all.preserve_aspect = true;
          }
          (mapAttrs (_: mergeAttrs {use = "all";}) {
            terminal.command = "wezterm start";
            volume.command = "pavucontrol";
            # TODO how can I get an emacsclient scratchpad to work? seems like I need class = "emacs" and match_by = "class"
          })
        ];
        shortcuts_menu = {
          engine = "$launcher";
          entries = {
            "Clipboard History" = [
              {
                name = "entry";
                command = "cliphist list";
                filter = "s/\\t.*//";
              }
              "cliphist decode '[entry]' | wl-copy"
            ];
            "Color Picker" = [
              {
                name = "format";
                options = ["hex" "rgb" "hsv" "hsl" "cmyk"];
              }
              "sleep 0.5; hyprpicker --format [format] | wl-copy"
            ];
            "Fetch Menu" = "pypr fetch_client_menu";
            # TODO need a good command for screenshot + annotation
          };
        };
        system_notifier.sources = [
          {
            command = "sudo journalctl --follow --catalog --dmesg";
            parser = "journal";
          }
        ];
      };
      home.packages = [pyprland.package];
      xdg.configFile."hypr/pyprland.toml" = mkIf (pyprland.settings != {}) {source = toml.generate "pyprland.toml" pyprland.settings;};
      systemd.user.services.pyprland = {
        Unit.After = ["graphical-session-pre.target"];
        Unit.PartOf = ["graphical-session.target"];
        Service.ExecStart = getExe pyprland.package;
        Service.Restart = "on-failure";
        Install.WantedBy = ["graphical-session.target"];
      };
      wayland.windowManager.hyprland.settings = {
        "$scratchpad" = "class:^(scratchpad)$";
        bind = [
          "$mod+SHIFT+CONTROL, Tab, exec, pypr expose"
          "$mod+ALT, return, pypr toggle term && hyprctl dispatch bringactivetotop"
        ];
        workspace = [
          "special:exposed,gapsout:60,gapsin:30,bordersize:5,border:true,shadow:false"
        ];
        windowrulev2 = [
          "float, $scratchpad"
          "size 80% 85%, $scratchpad"
          "workspace special silent, $scratchpad"
          "center, $scratchpad"
          "monitor desc:LG Electronics LG ULTRAFINE 111NTUWFF862, $scratchpad"
        ];
      };
    };
  };
}
