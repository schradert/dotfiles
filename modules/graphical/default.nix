{lib, ...}: let
  inherit (lib) mkDefault mkEnableOption mkIf toList;
in {
  canivete.pkgs.allowUnfree = ["android-studio-stable" "discord" "slack" "beeper"];
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
        # TODO android module
        home.sessionVariables.ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
        home.shellAliases.adb = "HOME=\"${config.home.sessionVariables.ANDROID_USER_HOME}\" ${pkgs.android-tools}/bin/adb";
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
          "legcord"
          "protonvpn"
          "quiet"
          "session"
          "zen-browser"
        ];
      };
    };
    nixos.modules.graphical = {
      config,
      perSystem,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
        dotfiles.services.yubikey.enable = mkDefault true;
        home-manager.sharedModules = toList {
          home.packages = with pkgs; [
            android-studio
            anki
            beeper
            bitwarden
            brave
            element-desktop
            protonvpn-gui
            quiet
            session-desktop
            simplex-chat-desktop

            # Discord
            discordo
            legcord
            webcord

            perSystem.inputs'.zen-browser.packages.twilight
          ];
          wayland.windowManager.hyprland.settings."$browser" = "brave";
        };
        services.desktopManager.plasma6.enable = true;
        services.displayManager.sddm.enable = mkDefault true;
        services.xserver.enable = true;
      };
    };
  };
}
