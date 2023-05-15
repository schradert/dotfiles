{
  config,
  lib,
  pkgs,
  nix-doom-emacs,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin isLinux system;
  inherit (lib) mkForce mkIf mkOption optionals types;
  options.home.extraPackages = mkOption {
    default = [ ];
    type = types.listOf types.package;
    description = "Extra nixpkgs derivations to include in user environment";
  };
  options.username = mkOption {
    default = "tristanschrader";
    type = types.str;
    description = "Location of the user's home directory";
  };
  options.isGraphical = mkOption {
    default = true;
    type = types.bool;
    description = "Whether the computer needs graphical apps or not";
  };
  imports = [ nix-doom-emacs.hmModule ];
  home = {
    username = config.username;
    homeDirectory =
      let
        homesParentDir =
          if isLinux then "/home"
          else if isDarwin then "/Users"
          else throw "System ${system} not supported"; 
      in
        mkForce "${homesParentDir}/${config.username}";
    stateVersion = "22.11";
    packages = config.home.extraPackages ++ (with pkgs; [
      aria2
      anki
      bitwarden-cli
      cheat
      cachix
      file
      dig
      docker
      glab
      iftop
      lsof
      nmap
      openssl
      rclone
      ripgrep
      signal-cli
      speedtest-cli
      thefuck
      tig
      tldr
      tree
      unzip
      xplr
    ] ++ optionals isLinux [
      nethogs 
      protonvpn-cli
    ] ++ optionals config.isGraphical [
# These don't seem to work to well on macOS right now.
# Saving these to be attempted later, but will leave on linux for now.
#     zoom-us
#     discord
#     slack
    ] ++ optionals (isLinux && config.isGraphical) [
      bitwarden
      brave-browser
      discord
      protonvpn-gui
      slack
      spicetify-cli
      spotify
      zoom-us
    ]);
  };
  programs = {
    bat.enable = true;
    dircolors.enable = true;
    direnv = { enable = true; nix-direnv.enable = true; };
    doom-emacs  = { enable = true; doomPrivateDir = ./doom.d; };
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
    vim = import ./vim { inherit pkgs; };
    wezterm = import ./wezterm { inherit pkgs; };
    zoxide.enable = true;
    zsh = import ./zsh { inherit pkgs; };
  };
  services.emacs = mkIf isLinux { enable = true; defaultEditor = true; };
in
{
  inherit options imports;
  config = { inherit home programs services; };
}
