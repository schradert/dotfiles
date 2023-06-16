{
  config,
  lib,
  pkgs,
  nix-doom-emacs,
  ...
}:
let
  inherit (builtins) fetchpatch fetchurl fromJSON readFile;
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
  options.doom.allPackages = mkOption {
    default = true;
    type = types.bool;
    description = "Whether to set up LSP for all languages I want to use Doom for";
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
    file.".skhdrc".source = mkIf isDarwin ./.skhdrc;
    file.".yabairc".source = mkIf isDarwin ./.yabairc;
    # This is tough to manage because, if activated, I can't update file contents
    # This is because it is symlinked to /nix/store, but I need to be able to update the files
    # With a settings reload without going through a nix build
#   file.".doom.d".source = mkIf isDarwin ./doom.d;
    packages = config.home.extraPackages ++ (with pkgs; [
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
      iftop
      libtool
      lsof
      nmap
      nodejs
      openssl
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
    ] ++ optionals config.doom.allPackages [
      cargo
      editorconfig-core-c
      gopls
      gotools
      gomodifytags
      gore
      gotests
      gnugrep
      graphviz
      haskellPackages.haskell-language-server
      haskellPackages.hoogle
      haskellPackages.cabal-install
      imagemagick
      ispell
      isync
      ktlint
      mu
      nil
      nixfmt
      nodePackages.js-beautify
      nodePackages.stylelint
      pandoc
      pipenv
      pngpaste
      python311Packages.grip
      python311Packages.isort
      python311Packages.nose
      python311Packages.pytest
      rust-analyzer
      rustc
      shellcheck
      taplo
      sqls
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
      godot
      protonvpn-gui
      slack
      spotify
      spicetify-cli
      zoom-us
    ]);
  };
  programs = {
    bat.enable = true;
    dircolors.enable = true;
    direnv = { enable = true; nix-direnv.enable = true; };
#   emacs = {
#     enable = true;
#     extraPackages = epkgs: with epkgs; [
#       editorconfig
#       org-roam-ui
#       peep-dired
#       rainbow-mode
#       kurecolor
#       imenu-list
#       org-brain
#       org-ql
#       magit-todos
#       tldr
#       kubernetes
#       kubernetes-evil
#     ];
#   };
    # doom-emacs  = { enable = true; doomPrivateDir = ./doom.d; };
    exa.enable = true;
    fzf = { enable = true; tmux.enableShellIntegration = true; };
    gh = {
      enable = true;
      settings = { editor = "emacs"; git_protocol = "ssh"; aliases.co = "pr checkout"; };
    };
    git = {
      enable = true;
      userEmail = "tristanschrader@proton.me";
      userName = "Tristan Schrader";
      extraConfig = {
        push.autoSetupRemote = true;
        color.status = "always";
        github.user = "schradert";
        gitlab.user = "schrader.tristan";
        # This is probably how our hosted Gitea repository will look
        # gitea.git.bunkbed.tech.user = "tristan";
      };
    };
    gpg.enable = true;
    home-manager.enable = true;
    htop.enable = true;
    jq.enable = true;
    k9s = {
      enable = true;
      skin =
        let
          inherit (pkgs) runCommand remarshal;
          path = fetchurl {
            url = "https://raw.githubusercontent.com/derailed/k9s/5a0a8f12e4cd2137badf8e2063c0ab3e3ff2f5cd/skins/dracula.yml";
            sha256 = "10is0kb0n6s0hd2lhyszrd6fln6clmhdbaw5faic5vlqg77hbjqs";
          };
          command = "remarshal -if yaml -i \"${path}\" -of json -o \"$out\"";
          jsonOutputDrv = runCommand "from-yaml" { nativeBuildInputs = [ remarshal ]; } command;
        in fromJSON (readFile jsonOutputDrv);
    };
    navi.enable = true;
    neovim = import ./nvim { inherit pkgs; };
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
