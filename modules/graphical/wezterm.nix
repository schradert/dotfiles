{
  canivete.deploy.system.homeModules.wezterm = {
    config,
    lib,
    perSystem,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
  in {
    options.dotfiles.programs.wezterm.enable = mkEnableOption "Wezterm";
    config = mkIf config.dotfiles.programs.wezterm.enable (mkMerge [
      {
        programs.wezterm = {
          enable = true;
          package = perSystem.inputs'.wezterm.packages.default;
          # Prevent WezTerm from overriding SSH_AUTH_SOCK from ssh-agent service
          extraConfig = "return {mux_enable_ssh_agent = false}";
        };
      }
      (mkIf pkgs.stdenv.isDarwin {
        launchd.agents.wezterm = {
          enable = true;
          config.RunAtLoad = true;
          config.KeepAlive.Crashed = true;
          config.Program = "${config.programs.wezterm.package}/Applications/WezTerm.app/Contents/MacOS/WezTerm";
        };
      })
      (mkIf config.dotfiles.graphical.hyprland.enable {
        wayland.windowManager.hyprland.settings."$terminal" = "wezterm";
      })
    ]);
  };
}
