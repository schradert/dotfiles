{
  flake.homeModules.default = {pkgs, ...}: {
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
      libtool
      lsof
      nmap
      nodejs
      openssl
      podman
      podman-compose
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
    home.file.".local/bin/docker".source = "${pkgs.podman}/bin/podman";
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
      wezterm.enable = true;
      zoxide.enable = true;
    };
  };
}
