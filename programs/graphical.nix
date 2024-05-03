{lib, ...}:
with lib; {
  flake.systemModules.graphical = {
    options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
  };
  flake.homeModules.graphical = {
    config,
    pkgs,
    ...
  }: {
    config = mkIf config.dotfiles.graphical.enable {
      dotfiles.editor = "emacs";
      programs.emacs.enable = true;
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
  flake.nixosModules.nixos-graphical = {
    config,
    flake,
    pkgs,
    ...
  }: {
    config = mkIf config.dotfiles.graphical.enable {
      fonts.packages = [pkgs.meslo-lgs-nf];
      home-manager.users.${flake.config.people.me} = {
        dotfiles.graphical.enable = true;
        home.packages = with pkgs; [
          android-studio
          anki
          beeper
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
        xkb.layout = "us";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };

      # Sound
      sound.enable = true;
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
}
