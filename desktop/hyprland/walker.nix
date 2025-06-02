{
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    ...
  }: {
    imports = [flake.inputs.walker.homeManagerModules.default];
    config = lib.mkIf (config.dotfiles.graphical.hyprland.enable or false) {
      wayland.windowManager.hyprland.settings = {
        "$launcher" = "walker";
        bind = ["$mod, SPACE, exec, $launcher"];
      };
      programs.walker = {
        enable = true;
        runAsService = true;
        config = {
          hot_reload_theme = true;
          plugins = [
            {
              name = "power";
              placeholder = "Power";
              switcher_only = true;
              recalculate_score = true;
              show_icon_when_single = true;
              entries = [
                {
                  label = "Shutdown";
                  icon = "system-shutdown";
                  exec = "shutdown now";
                }
                {
                  label = "Reboot";
                  icon = "system-reboot";
                  exec = "reboot";
                }
                {
                  label = "Lock Screen";
                  icon = "system-lock-screen";
                  exec = "hyprlock";
                }
              ];
            }
          ];
        };
        # theme.layout = {};
        # TODO dracula
        # theme.style = "";
        # config = {};
      };
    };
  };
}
