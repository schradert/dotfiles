{
  canivete.deploy.system.homeModules.common = {pkgs, ...}: {
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
      k3d
      lazydocker
      lazygit
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
      tig
      tldr
      tree
      unzip
      xplr
    ];
    programs = {
      bash.enable = true;
      bat.enable = true;
      btop.enable = true;
      dircolors.enable = true;
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      gpg.enable = true;
      home-manager.enable = true;
      htop.enable = true;
      jq.enable = true;
      navi.enable = true;
      zoxide.enable = true;
    };
  };
}
