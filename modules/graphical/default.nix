{lib, ...}: let
  inherit (lib) mkDefault mkEnableOption mkIf toList;
in {
  canivete.deploy = {
    system.modules.graphical.options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
    system.homeModules.graphical = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
        dotfiles.editor = "emacs";
        dotfiles.programs.wezterm.enable = true;
        dotfiles.programs.emacs.enable = true;
        home.packages = with pkgs; [
          discord
          gnutls
          harfbuzz
          libtool
          librsvg
          slack
          unbound
        ];
      };
    };
    darwin.modules.graphical = {config, ...}: {
      config = mkIf config.dotfiles.graphical.enable {
        homebrew.casks = [
          "android-studio"
          "anki"
          "beeper"
          "bitwarden"
          "brave-browser"
          "element"
          "godot"
          "protonvpn"
          "session"
          "signal"
        ];
      };
    };
    nixos.modules.graphical = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
        home-manager.sharedModules = toList {
          home.packages = with pkgs; [
            android-studio
            anki
            beeper
            bitwarden
            brave
            element-desktop
            godot_4
            protonvpn-gui
            session-desktop
            signal-desktop
          ];
          wayland.windowManager.hyprland.settings."$browser" = "brave";
        };
        services.desktopManager.plasma6.enable = true;
        services.displayManager.sddm.enable = mkDefault true;
        services.xserver = {
          enable = true;
          xkb.layout = "us";
        };
      };
    };
  };
}
