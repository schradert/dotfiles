{inputs, ...}: {
  flake.overlays.zellij-plugins = inputs.mynur.overlays.zellij-plugins;
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
      plugins = ps: (with ps; [harpoon room monocle zellij-forgot]) ++ [perSystem.inputs'.zjstatus.packages.default];
    };
    xdg.configFile."zellij/config.kdl".text = lib.mkForce (toKDL {} [
      (kdlNode "keybinds" [] {} [
        (kdlNode "shared_except" ["locked"] {} [
          (kdlNode "bind" ["Ctrl y"] {} [
            (kdlNode "LaunchOrFocusPlugin" ["harpoon"] {} [
              # FIXME harpoon panics when opening tab
              # TODO add search to select feature
              # TODO autofill by default with all panes
              (kdlNode "floating" ["true"] {} [])
              (kdlNode "move_to_focused_tab" ["true"] {} [])
            ])
          ])
          (kdlNode "bind" ["Ctrl u"] {} [
            (kdlNode "LaunchOrFocusPlugin" ["room"] {} [
              (kdlNode "floating" ["true"] {} [])
              (kdlNode "ignore_case" ["true"] {} [])
              (kdlNode "quick_jump" ["true"] {} [])
            ])
          ])
          (kdlNode "bind" ["F1"] {} [
            (kdlNode "LaunchOrFocusPlugin" ["monocle"] {} [
              # FIXME why is it not floating? behaves same as in_place + kiosk (below)
              (kdlNode "floating" ["true"] {} [])
            ])
            (kdlNode "SwitchToMode" ["Normal"] {} [])
          ])
          (kdlNode "bind" ["F2"] {} [
            (kdlNode "LaunchOrFocusPlugin" ["monocle"] {} [
              (kdlNode "in_place" ["true"] {} [])
              (kdlNode "kiosk" ["true"] {} [])
            ])
            (kdlNode "SwitchToMode" ["Normal"] {} [])
          ])
          (kdlNode "bind" ["Ctrl f"] {} [
            (kdlNode "LaunchOrFocusPlugin" ["zellij_forgot"] {} [])
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
