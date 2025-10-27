{
  dotfiles.devenv.git-hooks.hooks.typos.settings.ignored-words = ["ags"];
  dotfiles.home-manager = {
    config,
    lib,
    flake,
    perSystem,
    pkgs,
    ...
  }: let
    inherit (lib) flatten mkIf mkEnableOption getExe getExe';
    ags = getExe config.programs.ags.finalPackage;
    hyprctl = getExe' config.wayland.windowManager.hyprland.finalPackage "hyprctl";
    jq = getExe pkgs.jq;
  in {
    # TODO does AGS only work on Linux or can Darwin work too?
    imports = [flake.inputs.ags.homeManagerModules.default];
    options.dotfiles.services.ags.enable = mkEnableOption "AGS desktop shell service" // {default = config.dotfiles.graphical.hyprland.enable;};
    config = mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.services.ags.enable) {
      xdg.configFile."wpg/templates/ags.css.base".text = ''
        @define-color white {color15};
        @define-color black {color0};
        @define-color lightgray #a1a1a1;
        @define-color darkgray {color8};
        @define-color active {active};
        @define-color activedim rgba({active.rgb}, 0.6);
        @define-color red #ec6a88;
        @define-color hovered rgba({color8.rgb}, 0.6);
      '';
      programs.ags = {
        enable = true;
        systemd.enable = true;
        # TODO might need to use mkOutOfStoreSymlink for dynamic CSS file
        configDir = ./config;
        extraPackages = flatten [
          (with perSystem.inputs'.astal.packages; [hyprland wireplumber tray])
          config.dotfiles.graphical.gtk.switcher
          pkgs.rsass
        ];
      };
      wayland.windowManager.hyprland.settings.bind = [
        "$mod+CONTROL, SPACE, exec, ${ags} toggle bar-$(${hyprctl} -j monitors | ${jq} 'map(select(.focused)).[0].id')"
      ];
    };
  };
}
