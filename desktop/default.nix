{
  # TODO which of these should be moved to workstation?
  canivete.pkgs.allowUnfree = ["android-studio-stable"];
  dotfiles = {
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf config.dotfiles.graphical.enable {
        dotfiles.editor = "emacs";
        dotfiles.programs.wezterm.enable = true;
        dotfiles.programs.emacs.enable = true;
        editorconfig.enable = true;
        fonts.fontconfig.enable = true;
        home.packages = with pkgs;
          lib.mkMerge [
            [
              gnutls
              harfbuzz
              libtool
              librsvg
              unbound
            ]
            (lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
              android-studio
              fontfor
              kdePackages.kdenlive
              protonvpn-gui
            ])
          ];
        # TODO android module
        home.sessionVariables.ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
        home.shellAliases.adb = "HOME=\"${config.home.sessionVariables.ANDROID_USER_HOME}\" ${pkgs.android-tools}/bin/adb";
      };
    };
    darwin = {
      config,
      lib,
      ...
    }: {
      config = lib.mkIf config.dotfiles.profiles.workstation.enable {
        # TODO is this configuration even correct?
        homebrew.brews = ["libtool"];
        homebrew.casks = ["android-studio" "protonvpn"];
        # TODO why do I need this tap?
        homebrew.taps = ["cfergeau/crc"];
      };
    };
    nixos = {
      config,
      lib,
      ...
    }: {
      config = lib.mkIf config.dotfiles.graphical.enable {
        dotfiles.services.yubikey.enable = lib.mkDefault true;
        services.desktopManager.plasma6.enable = true;
        services.displayManager.sddm.enable = lib.mkDefault true;
        services.xserver.enable = true;
      };
    };
  };
}
