{
  inputs,
  nix,
  ...
}:
with nix; {
  flake.overlays.emacs = inputs.emacs-overlay.overlay;
  canivete.deploy = {
    nixos.homeModules.emacs = {config, ...}: {
      services.emacs = {
        enable = mkDefault true;
        defaultEditor = config.dotfiles.editor == "emacs";
        inherit (config.programs.emacs) package;
        client.enable = true;
      };
    };
    system.homeModules.emacs = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = mkIf config.programs.emacs.enable {
        programs.emacs.package = pkgs.emacs-unstable-pgtk;
        home = let
          emacs = "${config.xdg.configHome}/emacs";
        in {
          # TODO why do I need to deactivate doom sync? seems to fail on some nodes...
          activation.doomInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
            export PATH=$PATH:${config.programs.emacs.package}/bin:${pkgs.git}/bin:${emacs}/bin
            if [[ ! -d ${emacs} ]]; then
              git clone --depth 1 https://github.com/doomemacs/doomemacs ${emacs}
              doom install
            # else
              # doom sync
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
            ktlint
            nil
            nixfmt-classic
            nodePackages.js-beautify
            nodePackages.stylelint
            pandoc
            pipenv
            python312Packages.grip
            python312Packages.isort
            python312Packages.pytest
            rust-analyzer
            rustc
            shellcheck
            taplo
            sqls
          ];
          # TODO add doom to the sessionPath (doesn't work with config.home.homeDirectory either!)
          sessionPath = ["${emacs}/bin"];
        };
      };
    };
  };
}
