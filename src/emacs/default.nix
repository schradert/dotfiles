{inputs, ...}: {
  flake.overlays.emacs = inputs.emacs-overlay.overlay;
  flake.homeModules.emacs = {
    config,
    flake,
    lib,
    nix,
    pkgs,
    ...
  }:
    with lib;
      mkMerge [
        {
          services.emacs = {
            enable = mkDefault pkgs.stdenv.isLinux;
            defaultEditor = config.dotfiles.editor == "emacs";
            # package = inputs.emacs-overlay.packages.${system}.emacs-unstable-pgtk;
            package = pkgs.emacs-unstable-pgtk;
          };
        }
        (mkIf config.services.emacs.enable (mkMerge [
          {
            programs.zsh.initExtraLines = nix.toList "export PATH=\"$HOME/.config/emacs/bin:$PATH\"";
            home = {
              file.".doom.d/init.el".source = ./init.el;
              file.".doom.d/config.org".source = ./config.org;
              # TODO get elfeed working
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
            };
          }
          (mkIf config.programs.git.enable {
            home.activation.doomInstallation = hm.dag.entryAfter ["linkGeneration"] ''
              if [ ! -d "$XDG_CONFIG_HOME/emacs" ]; then
                ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$XDG_CONFIG_HOME/emacs"
                "$XDG_CONFIG_HOME/emacs/bin/doom" install
              fi
            '';
          })
        ]))
      ];
}
