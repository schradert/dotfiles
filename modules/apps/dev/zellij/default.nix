{
  dotfiles.nixos = {
    config,
    flake,
    lib,
    ...
  }: {
    nixpkgs.overlays = lib.mkIf config.dotfiles.profiles.client.workstation.enable (with flake.inputs; [
      mynur.overlays.zellij
      mynur.overlays.zellij-plugins
      fenix.overlays.default
    ]);
  };
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    perSystem,
    pkgs,
    ...
  }: let
    kdl' = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/jrobsonchase/nixos-config/8ea380ad196e630044846f06945131602ec7056f/lib/kdl.nix";
      hash = "sha256-TEguiZPHkSCpGpycZWqMqAsjf4Woz5WmK9TsEUXNx5o=";
    };
    inherit (import kdl' {inherit lib;}) kdlNode toKDL;
    pluginSettings = {};
  in {
    imports = [flake.inputs.mynur.homeManagerModules.zellij-plugins];
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      programs.zellij = {
        enable = true;
        enableZshIntegration = true;
        # TODO zjstatus
        # TODO jbz?
        # TODO multitask?
        plugins = ps:
          (with ps; [
            room
            monocle
            zellij-forgot
            zj-quit
            zellij-choose-tree
            zellij-sessionizer
          ])
          ++ [perSystem.inputs'.zjstatus.packages.default];
      };
      xdg.configFile."zellij/layouts".source = ./layouts;
      xdg.configFile."zellij/config.kdl".text = lib.mkForce (toKDL {} [
        (kdlNode "plugins" [] {} (lib.mapAttrsToList (name: cfg: kdlNode name [] cfg (pluginSettings.${name} or [])) config.programs.zellij.settings.plugins))
        (kdlNode "keybinds" [] {} [
          (kdlNode "shared_except" ["locked"] {} [
            (kdlNode "bind" ["Ctrl y"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["room"] {} [
                (kdlNode "floating" [true] {} [])
                (kdlNode "ignore_case" [true] {} [])
                (kdlNode "quick_jump" [true] {} [])
              ])
            ])
            (kdlNode "bind" ["Ctrl f"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["monocle"] {} [
                (kdlNode "floating" [true] {} [])
              ])
              (kdlNode "SwitchToMode" ["Normal"] {} [])
            ])
            (kdlNode "bind" ["Ctrl F"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["monocle"] {} [
                (kdlNode "in_place" [true] {} [])
                (kdlNode "kiosk" [true] {} [])
              ])
              (kdlNode "SwitchToMode" ["Normal"] {} [])
            ])
            (kdlNode "bind" ["Ctrl H"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["zellij_forgot"] {} [
                (kdlNode "floating" [true] {} [])
              ])
            ])
            (kdlNode "bind" ["Ctrl q"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["zj-quit"] {} [
                (kdlNode "floating" [true] {} [])
              ])
            ])
          ])
          (kdlNode "tmux" [] {} [
            (kdlNode "bind" ["s"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["zellij-choose-tree"] {} [
                (kdlNode "floating" [true] {} [])
                (kdlNode "move_to_focused_tab" [true] {} [])
                (kdlNode "show_plugins" [true] {} [])
              ])
            ])
            (kdlNode "bind" ["g"] {} [
              (kdlNode "LaunchOrFocusPlugin" ["zellij-sessionizer"] {} [
                (kdlNode "floating" [true] {} [])
                (kdlNode "move_to_focused_tab" [true] {} [])
                (kdlNode "cwd" ["/"] {} [])
                (kdlNode "root_dirs" ["${config.home.homeDirectory}/Projects"] {} [])
                (kdlNode "session_layout" ["project"] {} [])
              ])
              (kdlNode "SwitchToMode" ["Locked"] {} [])
            ])
          ])
        ])
      ]);
    };
  };
}
