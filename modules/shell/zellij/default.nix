{inputs, ...}: {
  flake.overlays.zellij = inputs.mynur.overlays.zellij;
  canivete.deploy.system.homeModules.zellij = {
    config,
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
    imports = [inputs.mynur.homeManagerModules.zellij-plugins];
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
    xdg.configFile."zellij/config.kdl".text = lib.mkForce (toKDL {} [
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
      (kdlNode "theme" ["dracula"] {} [])
      (kdlNode "plugins" [] {} (lib.mapAttrsToList (name: cfg: kdlNode name [] cfg (pluginSettings.${name} or [])) config.programs.zellij.settings.plugins))
    ]);
    xdg.configFile."zellij/layouts".source = ./layouts;
    xdg.configFile."zellij/themes/dracula.kdl".source = let
      source = pkgs.fetchFromGitHub {
        owner = "dracula";
        repo = "zellij";
        rev = "master";
        hash = "sha256-Sqj9EhDhr5Kv9x9GwfPUvNOQocGzbVScVSGnR0/yf7Q=";
      };
    in "${source}/dracula.kdl";
  };
}
