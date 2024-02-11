{
  flake.homeModules.graphical = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      options.dotfiles.graphical.enable = mkEnableOption "graphical tools (i.e. not headless)";
      config = mkIf config.dotfiles.graphical.enable (mkMerge [
        {
          dotfiles.editor = "emacs";
          home.packages = with pkgs; [
            gnutls
            harfbuzz
            libtool
            librsvg
            podman
            unbound
            # TODO (Tristan): figure out how to run docker as a home-manager service
            # docker
            # TODO (Tristan): fix ENOTFOUND -3008 getaddrinfo registry.yarnpkg.com for element-desktop build
            # element-desktop
            # TODO (Tristan): figure out why these graphical apps are not installing!
            # zoom-us
            # raycast
            # slack
          ];
        }
        (mkIf pkgs.stdenv.isDarwin {
          # TODO why do I need pngpaste
          home.packages = with pkgs; [discord pngpaste];
          home.homeDirectory = "/Users/${config.home.username}";
        })
        (mkIf pkgs.stdenv.isLinux {
          home.packages = with pkgs; [
            android-studio
            anki
            bitwarden
            brave
            godot3
            protonvpn-gui
          ];
        })
      ]);
    };
  flake.nixosModules.nixos-graphical = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.enable = lib.mkEnableOption "graphical tools (i.e. not headless)";
    config = lib.mkIf config.dotfiles.graphical.enable {
      fonts.packages = [pkgs.meslo-lgs-nf];
      hardware.pulseaudio.enable = true;
      home-manager.users.${flake.config.people.me}.dotfiles.graphical.enable = true;
      services.xserver = {
        enable = true;
        layout = "us";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };
      sound.enable = true;
    };
  };
  flake.darwinModules_.nixos-graphical = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.graphical.enable = lib.mkEnableOption "graphical tools (i.e. not headless)";
    config = lib.mkIf config.dotfiles.graphical.enable {
      fonts.packages = [pkgs.meslo-lgs-nf];
      hardware.pulseaudio.enable = true;
      home-manager.users.${flake.config.people.me}.dotfiles.graphical.enable = true;
      services.xserver = {
        enable = true;
        layout = "us";
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };
      sound.enable = true;
    };
  };
}
