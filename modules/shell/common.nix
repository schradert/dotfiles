{inputs, ...}: {
  canivete.deploy.system.homeModules.common = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge;
    inherit (config) xdg;
  in {
    options.dotfiles.common = mkEnableOption "common shell utilities" // {default = true;};
    config = mkIf config.dotfiles.common {
      dotfiles.programs.git.enable = true;
      home.sessionVariables = {
        XDG_CACHE_HOME = xdg.cacheHome;
        XDG_CONFIG_HOME = xdg.configHome;
        XDG_DATA_HOME = xdg.dataHome;
        XDG_STATE_HOME = xdg.stateHome;
        # TODO how can I get the user UID?
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      home.packages = mkMerge [
        (with pkgs; [
          aria2
          bottom
          cheat
          cmake
          dig
          fd
          file
          glab
          gping
          hwatch
          iftop
          inxi
          libtool
          lsof
          nodejs
          openssl
          procps
          ranger
          ripgrep
          rustscan
          speedtest-cli
          sqlite
          # TODO https://github.com/nvbn/thefuck
          thefuck
          tldr
          tree
          unzip
          xplr
        ])
        (mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
          kmon
          # TODO build psicircle
          # NOTE https://gitlab.com/mildlyparallel/pscircle
          systeroid
        ]))
      ];
      fonts.fontconfig.enable = true;
      nixpkgs.overlays = [inputs.nur.overlays.default];
      programs = {
        bash.enable = true;
        btop.enable = true;
        dircolors.enable = true;
        eza.enable = true;
        home-manager.enable = true;
        htop.enable = true;
        jq.enable = true;
        nix-your-shell.enable = true;
        starship.enable = true;
        zoxide.enable = true;
      };
    };
  };
}
