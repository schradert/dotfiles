{lib, ...}:
with lib; {
  flake.homeModules.graphical = {
    config,
    pkgs,
    ...
  }: {
    config = mkIf config.dotfiles.graphical.enable {
      dotfiles.editor = "emacs";
      home.packages = with pkgs; [
        anki
        discord
        gnutls
        harfbuzz
        libtool
        librsvg
        spotify
        unbound
      ];
    };
  };
  flake.nixosModules.nixos-graphical = {
    config,
    flake,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
    config = mkIf config.dotfiles.graphical.enable {
      fonts.packages = [pkgs.meslo-lgs-nf];
      hardware.pulseaudio.enable = true;
      home-manager.users.${flake.config.people.me} = {
        dotfiles.graphical.enable = true;
        home.packages = with pkgs; [
          android-studio
          bitwarden
          brave
          element-desktop
          godot_4
          podman-desktop
          protonvpn-gui
          session-desktop
          signal-desktop
        ];
      };
      services.xserver = {
        enable = true;
        layout = "us";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };
      sound.enable = true;
    };
  };
  flake.darwinModules_.darwin-graphical = {
    config,
    flake,
    nix,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.enable = nix.mkEnabledOption "graphical tools (i.e. not headless)";
    config = mkIf config.dotfiles.graphical.enable {
      fonts.fonts = [pkgs.meslo-lgs-nf];
      home-manager.users.${flake.config.people.me} = {
        dotfiles.graphical.enable = true;
        home.packages = with pkgs; [discord pngpaste raycast];
        home.homeDirectory = "/Users/${config.home.username}";
      };
      homebrew.enable = true;
      homebrew.casks = [
        "android-studio"
        "bitwarden"
        "brave-browser"
        "element"
        "godot"
        "lulu"
        "podman-desktop"
        "protonvpn"
        "session"
        "signal"
      ];
    };
  };
}
