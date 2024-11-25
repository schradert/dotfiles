{
  canivete.deploy.nixos.homeModules.walker = {config, flake, lib, ...}: {
    imports = [flake.inputs.walker.homeManagerModules.default];
    config = lib.mkIf config.dotfiles.graphical.hyprland.enable {
      wayland.windowManager.hyprland.settings = {
        "$launcher" = "walker";
        bind = ["$mod, SPACE, exec, $launcher"];
      };
      programs.walker = {
        enable = true;
        runAsService = true;
        # theme.layout = {};
        # TODO dracula
        # theme.style = "";
        # config = {};
      };
    };
  };
}
