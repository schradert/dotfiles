{
  config,
  inputs,
  nix,
  ...
}:
with nix; {
  options.flake = nix.mkSubmoduleOptions {
    homeModules = nix.mkOpenModuleOption {
      description = nix.mkDoc "Home-Manager modules";
    };
  };
  config.flake.homeModules.home = home @ {pkgs, ...}: {
    options.dotfiles.editor = mkOption {
      type = enum ["vim" "emacs"];
      default = "vim";
      example = "emacs";
      description = mdDoc "Default editor to use for profile";
    };
    config = {
      home.username = config.people.me;
      home.homeDirectory = "/${if pkgs.stdenv.isDarwin then "Users" else "home"}/${config.people.me}";
      home.sessionPath = ["${home.config.home.homeDirectory}/.local/bin"];
      home.stateVersion = "23.05";
      home.packages = with pkgs; [
        aria2
        cheat
        cmake
        dig
        fd
        file
        glab
        iftop
        k3d
        libtool
        lsof
        nmap
        nodejs
        openssl
        podman
        podman-compose
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
        fzf.tmux.enableShellIntegration = home.config.programs.tmux.enable;
        gpg.enable = true;
        home-manager.enable = true;
        htop.enable = true;
        jq.enable = true;
        navi.enable = true;
        wezterm.enable = true;
        zoxide.enable = true;
      };
      sops.defaultSopsFile = ./dev/sops.yaml;
      sops.age.keyFile = "${home.config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
  };
}
