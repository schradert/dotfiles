{inputs, ...}: {
  flake.overlays.emacs = inputs.emacs-overlay.overlay;
  canivete.deploy = {
    nixos.homeModules.emacs = {
      config,
      lib,
      ...
    }: {
      services.emacs = {
        enable = lib.mkDefault true;
        defaultEditor = config.dotfiles.editor == "emacs";
        inherit (config.dotfiles.programs.emacs) package;
        client.enable = true;
      };
    };
    system.homeModules.emacs = {
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) concatStringsSep flatten getExe makeBinPath mkIf mkDefault mkOption hm types;
      inherit (pkgs) fetchFromGitHub wrapProgram emacs-unstable-pgtk nerdfonts;
      src = fetchFromGitHub {
        owner = "doomemacs";
        repo = "doomemacs";
        rev = "7bc39f2c1402794e76ea10b781dfe586fed7253b";
        hash = "sha256-bEvS68Q/KwVJU97f2Q+jRG7Z4PJPfWDr8rw4HAbCI3E=";
        leaveDotGit = true;
      };
      path = makeBinPath (flatten [
        config.programs.git.package
        (with pkgs; [
          (aspellWithDicts (dicts: with dicts; [ar de en es fi fr la pt_BR pt_PT ru tr en-computers en-science]))
          cargo
          coreutils-prefixed
          fd
          findutils
          fontconfig
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
          ripgrep
          rust-analyzer
          rustc
          shellcheck
          taplo
          sqls
          zls
          zig
        ])
      ]);
      emacsDir = builtins.toString src;
      loadFile = "${doomDir}/profiles/load.el";
      doomDirRelative = "doom";
      doomDir = "${config.xdg.configHome}/${doomDirRelative}";
      args = concatStringsSep " " [
        "--prefix PATH : ${path}"
        "--set EMACS ${getExe config.dotfiles.programs.emacs.package}"
        "--set EMACSDIR ${emacsDir}"
        "--set DOOMDIR \"${doomDir}\""
        "--set DOOMPROFILELOADFILE \"${loadFile}\""
        "--set DOOMLOCALDIR \"${doomDir}/local\""
      ];
      doom = wrapProgram src "doom" "doom" args {};
    in {
      options.dotfiles.programs.emacs.package = mkOption {
        type = types.package;
        description = "Final Emacs package with overrides";
        default = wrapProgram config.programs.emacs.package "emacs" "emacs" "--add-flags \"--init-directory ${emacsDir}\"" {};
      };
      config = mkIf config.programs.emacs.enable {
        # TODO why is the loadFile not created? why am I having so much issue with running this basic command?
        # home.activation.doom = hm.dag.entryAfter ["writeBoundary"] "${getExe doom} $([[ ! -f ${loadFile} ]] && echo install --no-env || echo sync)";
        home.activation.doom = hm.dag.entryAfter ["writeBoundary"] "${getExe doom} $([[ ! -d ${doomDir} ]] && echo install --no-env || echo sync)";
        # NOTE fonts only detected in home.packages
        home.packages = [doom (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})];
        programs.emacs.package = mkDefault emacs-unstable-pgtk;
        programs.git.extraConfig.safe.directory = emacsDir;
        xdg.configFile."${doomDirRelative}/config.org".source = ./config.org;
        xdg.configFile."${doomDirRelative}/init.el".source = ./init.el;
      };
    };
  };
}
