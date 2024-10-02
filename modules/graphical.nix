{nix, ...}:
with nix; {
  canivete.deploy = {
    system.modules.graphical.options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
    system.homeModules.graphical = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
        dotfiles.editor = "emacs";
        programs.emacs.enable = true;
        programs.wezterm.enable = true;
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
    nixos.homeModules.graphical = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
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
      };
    };
    nixos.modules.graphical = {
      config,
      pkgs,
      ...
    }: {
      config = mkIf config.dotfiles.graphical.enable {
        fonts.packages = [pkgs.meslo-lgs-nf];
        home-manager.sharedModules = [{dotfiles.graphical.enable = true;}];
        services.displayManager.sddm.enable = mkDefault true;
        services.xserver = {
          enable = true;
          xkb.layout = "us";
          desktopManager.plasma6.enable = true;
        };

        # Sound
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.enable = true;
        };
      };
    };
  };
}
