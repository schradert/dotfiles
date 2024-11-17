{
  canivete.deploy.system.homeModules.wezterm = {config, lib, perSystem, pkgs, ...}: let
    inherit (lib) mkEnableOption mkIf mkMerge;
  in {
    options.dotfiles.programs.wezterm.enable = mkEnableOption "Wezterm";
    config = mkIf config.dotfiles.programs.wezterm.enable (mkMerge [
      {
        programs.wezterm.enable = true;
        programs.wezterm.package = perSystem.inputs'.wezterm.packages.default;
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
