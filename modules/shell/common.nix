{
  canivete.deploy.system.homeModules.common = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.common = lib.mkEnableOption "common shell utilities";
    config = lib.mkIf config.dotfiles.common {
      home.packages = with pkgs; [
        aria2
        cheat
        cmake
        dig
        fd
        file
        glab
        iftop
        inxi
        libtool
        lsof
        nmap
        nodejs
        openssl
        procps
        ranger
        rclone
        ripgrep
        speedtest-cli
        sqlite
        thefuck
        tldr
        tree
        unzip
        xplr
      ];
      fonts.fontconfig.enable = true;
      programs = {
        bash.enable = true;
        bat.enable = true;
        btop.enable = true;
        dircolors.enable = true;
        eza.enable = true;
        home-manager.enable = true;
        htop.enable = true;
        jq.enable = true;
        navi.enable = true;
        zoxide.enable = true;
      };
    };
  };
}
