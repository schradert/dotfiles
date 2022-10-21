{ pkgs, lib, config, ... }:
let
  macos = "aarch64-darwin";
  meNeovim = import ./nvim.nix;
  meVim = import ./vim.nix;
  meZsh = import ./zsh.nix;
in {
  home = rec {
    enableNixpkgsReleaseCheck = true;
    stateVersion = "22.11";
    packages = with pkgs; [
      cheat
      dig
      exa
      git-filter-repo
      nodejs
      python310Packages.setuptools
      poetry
      shellcheck
      speedtest-cli
      thefuck
      tldr
      universal-ctags
    ];
    username = "tristan";
    homeDirectory =
      let prefix = (if pkgs.system == macos then "/Users" else "/home");
      in "${prefix}/${username}";
  };
  programs = {
    bat.enable = true;
    dircolors.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    emacs.enable = true;
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
    gh.enable = true;
    git = {
      userEmail = "tristan@climaxfoods.com";
      userName = "Tristan Schrader";
    };
    gpg.enable = true;
    home-manager.enable = true;
    jq.enable = true;
    navi.enable = true;
    neovim = meNeovim pkgs;
    tmux = {
      enable = true;
      clock24 = true;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
          '';
        }
        pain-control
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
          '';
        }
        sensible
        tmux-thumbs
        vim-tmux-navigator
        yank
        {
          plugin = dracula;
          extraConfig = ''
            set -g @dracula-show-battery false
            set -g @dracula-show-powerline true
	          set -g @dracula-refresh-rate 10
	        '';
        }
      ];
      extraConfig = ''
        set -g mouse on
      '';
    };
    vim = meVim pkgs;
    zoxide.enable = true;
    zsh = meZsh { inherit pkgs lib config; };
  };
  manual.json.enable = true;
  manual.html.enable = true;
  news.display = "show";
} //
(if pkgs.system == "aarch64-darwin" then {} else {
  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
    pbgopy.enable = true;
  };
})

