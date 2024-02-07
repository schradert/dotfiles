{
  config,
  pkgs,
  flake,
  inputs,
  lib,
  ...
}: {
  services.emacs = {
    enable = pkgs.stdenv.isLinux;
    defaultEditor = true;
    package = pkgs.emacs-unstable-pgtk;
  };
  home = {
    file.".doom.d/init.el".source = ./init.el;
    file.".doom.d/config.org".source = ./config.org;
    packages = with pkgs; [
      config.services.emacs.package
  
      # dependencies
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
      python311Packages.grip
      python311Packages.isort
      python311Packages.nose
      python311Packages.pytest
      rust-analyzer
      rustc
      shellcheck
      taplo
      sqls
    ];
    activation.doomInstallation = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$XDG_CONFIG_HOME/emacs"
        "$XDG_CONFIG_HOME/emacs/bin/doom" install
      fi
    '';
  };
}
