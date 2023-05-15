{ pkgs, nix-doom-emacs, me ? { packages = [ ]; groups = [ ]; }, ... }:
let
  tristan.users = {
    isNormalUser = true;
    home = "/home/tristan";
    description = "Tristan Schrader";
    extraGroups = [ "wheel" "tty" ] ++ me.groups;
    shell = pkgs.zsh;
  };
  tristan.home-manager = {
    imports = [ nix-doom-emacs.hmModule ];
    home = {
      stateVersion = "22.11";
      packages = (with pkgs; [
        aria2
        cheat
        cachix
        file
        dig
        glab
        iftop
        lsof
        nethogs
        nmap
        openssl
        rclone
        ripgrep
        speedtest-cli
        thefuck
        tig
        tldr
        tree
        unzip
        xplr
      ]) ++ me.packages;
    };
    programs = {
      bat.enable = true;
      dircolors.enable = true;
      direnv = { enable = true; nix-direnv.enable = true; };
      doom-emacs = { enable = true; doomPrivateDir = ./doom.d; };
      exa.enable = true;
      fzf = { enable = true; tmux.enableShellIntegration = true; };
      gh = {
        enable = true;
        settings = { editor = "vim"; git_protocol = "ssh"; aliases.co = "pr checkout"; };
      };
      git = {
        enable = true;
        userEmail = "tristanschrader@proton.me";
        userName = "Tristan Schrader";
        extraConfig = { push.autoSetupRemote = true; color.status = "always"; };
      };
      gpg.enable = true;
      home-manager.enable = true;
      htop.enable = true;
      jq.enable = true;
      navi.enable = true;
      tmux = {
        enable = true;
        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = dracula;
            extraConfig = ''
              set -g @dracula-show-battery false
              set -g @dracula-show-powerline true
              set -g @dracula-refresh-rate 10
            '';
          }
        ];
      };
      zoxide.enable = true;
    };
    services.emacs = { enable = true; defaultEditor = true; };
    xdg.configFile."glab-cli/config.yml".text = ''
      git_protocol: ssh
      editor: vim
      browser: firefox
      glamour_style: dark
      check_update: true
      display_hyperlinks: true
    '';
    xdg.configFile."glab-cli/aliases.yml".text = ''
      ci: pipeline ci
      co: mr checkout
    '';
    vim = import ./vim { inherit pkgs; };
    wezterm = import ./wezterm { inherit pkgs; };
    zsh = import ./zsh { inherit pkgs; };
  };
in
{
  users.users.tristan = tristan.users;
  home-manager.users.tristan = tristan.home-manager;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
}
