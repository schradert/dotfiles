{ self, config, ... }:
{
  flake = {
    homeModules.common = ({ pkgs, lib, ... }: {
      imports = [
        ./vim
        ./zsh
        ./nvim
        ./git
        ./ssh
        ./tmux
        ./k9s
      ];
      home.username = lib.mkDefault config.people.myself;
      home.stateVersion = "23.05";
      home.packages = with pkgs; [
        aria2
        anki
        bitwarden-cli
        cheat
        cachix
        cmake
        dig
        fd
        file
        glab
        gyb
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
        signal-cli
        speedtest-cli
        sqlite
        thefuck
        tig
        tldr
        tree
        unzip
        wordnet
        xplr
      ];
      programs = {
        bat.enable = true;
        dircolors.enable = true;
        direnv = { enable = true; nix-direnv.enable = true; };
        exa.enable = true;
        fzf = { enable = true; tmux.enableShellIntegration = true; };
        gpg.enable = true;
        home-manager.enable = true;
        htop.enable = true;
        jq.enable = true;
        navi.enable = true;
        wezterm.enable = true;
        zoxide.enable = true;
      };
    });
    homeModules.graphical = ({ pkgs, lib, ... }: {
      imports = [
        self.homeModules.common
        ./emacs
      ];
      home.packages = with pkgs; [
# TODO (Tristan): figure out how to run docker as a home-manager service
#       docker
        podman
        libtool
        librsvg
        harfbuzz
        gnutls
        unbound
# TODO (Tristan): fix ENOTFOUND -3008 getaddrinfo registry.yarnpkg.com for element-desktop build
#       element-desktop
# TODO (Tristan): figure out why these graphical apps are not installing!
#       zoom-us
#       raycast
#       slack
      ];
    });
    homeModules.linux-graphical = {
      imports = [ self.homeModules.graphical ./spicetify/linux.nix ];
    };
    homeModules.darwin-graphical = ({ config, pkgs, lib, ... }: {
      imports = [
        self.homeModules.graphical
        ./brew
        ./spicetify/darwin.nix
      ];
      home.packages = with pkgs; [ skhd discord ];
      home.homeDirectory = "/Users/${config.home.username}";
      home.file.".skhdrc".source = ./.skhdrc;
      home.file.".yabairc".source = ./.yabairc;
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "discord" ];
    });
  };
}
