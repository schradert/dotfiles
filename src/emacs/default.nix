{
  inputs,
  nix,
  ...
}:
with nix; {
  flake.overlays.emacs = inputs.emacs-overlay.overlay;
  flake.homeModules.emacs = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.programs.emacs.enable (mkMerge [
      {
        programs.emacs.package = pkgs.emacs-unstable-pgtk;
        home = let
          emacs = "${config.xdg.configHome}/emacs";
        in {
          activation.doomInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
            export PATH=$PATH:${config.programs.emacs.package}/bin:${pkgs.git}/bin:${emacs}/bin
            if [[ ! -d ${emacs} ]]; then
              git clone --depth 1 https://github.com/doomemacs/doomemacs ${emacs}
              doom install
            else
              doom sync
            fi
          '';
          file.".doom.d/init.el".source = ./init.el;
          file.".doom.d/config.org".source = ./config.org;
          # TODO get elfeed working
          packages = with pkgs; [
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
          sessionPath = ["${emacs}/bin"];
        };
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        services.emacs = {
          enable = mkDefault true;
          defaultEditor = config.dotfiles.editor == "emacs";
          package = config.programs.emacs.package;
          client.enable = true;
        };
      })
    ]);
  };
}
