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
      home.username = mkDefault config.people.me;
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
  # TODO figure out a different implementation for import home-manager modules
  # For some reason it was complaining that imports doesn't exist, yet it lets me set options
  config.flake.nixosModules =
    mapAttrs (_: module: {
      home-manager.users.${config.people.me} = module;
    })
    inputs.self.homeModules;
  config.flake.darwinModules_ =
    mapAttrs (_: module: {
      home-manager.users.${config.people.me} = module;
    })
    # Spicetify-nix only supports x86_64-linux
    (removeAttrs inputs.self.homeModules ["spicetify" "spicetify-nix"]);
}
