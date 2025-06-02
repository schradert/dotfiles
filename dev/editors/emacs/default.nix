{inputs, ...}: {
  flake.overlays.emacs = inputs.emacs-overlay.overlay;
  canivete.pkgs.allowUnfree = ["aspell-dict-en-science"];
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://en.wiktionary.org/wiki/%s"];
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (builtins) baseNameOf toString;
    inherit (config.dotfiles.programs) emacs;
    inherit (lib) concat concatStringsSep flatten getExe listToAttrs makeBinPath mapAttrsToList mkEnableOption mkIf mkMerge mkOption mkPackageOption optionals pipe removePrefix types;
    inherit (pkgs) fetchFromGitHub nerd-fonts stdenv wrapFlags wrapProgram;
    inherit (stdenv.hostPlatform) isLinux;
    inherit (emacs.env) EMACSDIR DOOMDIR;
    inherit (types) listOf path package lazyAttrsOf str;
    doomDirRelative = "doom";
    src = fetchFromGitHub {
      name = "doom";
      owner = "doomemacs";
      repo = "doomemacs";
      rev = "2bc052425ca45a41532be0648ebd976d1bd2e6c1";
      hash = "sha256-CZVfxijPWe3fhGV5OBAn+Z4S7XjlSUsJ1iPt40Ntu1Q=";
      leaveDotGit = true;
    };
    doom' = wrapFlags emacs.doom "--run \"${getExe emacs.tangle}\"";
  in {
    # TODO use programs.emacs as a base!
    options.dotfiles.programs.emacs = {
      enable = mkEnableOption "Graphical emacs";
      package = mkPackageOption pkgs "emacs-pgtk" {};
      orgFiles = mkOption {
        type = listOf path;
        default = [];
      };
      dependencies = mkOption {
        type = listOf package;
        default = [];
      };
      finalPackage = mkOption {
        type = package;
        readOnly = true;
        description = "Final Emacs package with overrides";
        default = wrapProgram emacs.package "emacs" "emacs" "--add-flags \"--init-directory ${EMACSDIR}\"" {};
      };
      env = mkOption {
        type = lazyAttrsOf str;
        default = {};
        description = "Environment variables";
      };

      doom = mkOption {
        type = package;
        description = "Doom profile";
      };
      tangle = mkOption {
        type = package;
        description = "Configuration tangle script";
      };
    };
    config = mkIf emacs.enable (mkMerge [
      {
        # TODO why is the loadFile not created? why am I having so much issue with running this basic command?
        # TODO why am I getting "cannot resolve host: github.com when running doom sync? seems like some packages are picked up just fine
        # home.activation.doom = hm.dag.entryAfter ["writeBoundary"] "${getExe doom} $([[ ! -f ${loadFile} ]] && echo install --no-env || echo sync)";
        # home.activation.doom = hm.dag.entryAfter ["writeBoundary"] "${getExe doom} $([[ ! -d ${doomDir} ]] && echo install --no-env || echo sync)";
        # NOTE fonts only detected in home.packages
        home.packages = [doom' nerd-fonts.symbols-only];
        programs.git.extraConfig.safe.directory = EMACSDIR;
        dotfiles.programs.emacs = {
          dependencies = flatten [
            emacs.finalPackage
            config.programs.git.package
            (with pkgs; [
              (aspellWithDicts (dicts: with dicts; [ar de en es fi fr la pt_BR pt_PT ru tr en-computers en-science]))
              cmigemo
              coreutils-prefixed
              fd
              findutils
              ffmpegthumbnailer
              fontconfig
              gcc
              gnugrep
              gnumake
              gnuplot
              gnutls
              html-tidy
              imagemagick
              languagetool
              maim
              mediainfo
              nil
              nixfmt-rfc-style
              nodePackages.js-beautify
              nodePackages.stylelint
              parinfer-rust-emacs
              poppler
              python312Packages.grip
              sops
              sqls
              taplo
              tuntox

              # Chinese
              librime
              gnumake
              cmake
              gcc
            ])
            # debugger
            (with pkgs; [nodejs lldb unzip (optionals isLinux [gdb])])
            # lookup
            (with pkgs; [ripgrep sqlite wordnet])
            # everywhere dependencies
            (optionals isLinux (with pkgs; [
              # NOTE wayland substitutes
              # wl-clipboard-rs
              # wtype, ydotool, wlrctl
              # wlprop
              # ???
              xclip
              xdotool
              xorg.xprop
              xorg.xwininfo
            ]))
          ];
          doom = pipe emacs.env [
            (mapAttrsToList (name: value: "--set ${name} \"${value}\""))
            (concat ["--prefix PATH : ${makeBinPath emacs.dependencies}"])
            (concatStringsSep " ")
            (wrapFlags src)
          ];
          env = {
            USERDIR = config.home.homeDirectory;
            EMACS = getExe emacs.finalPackage;
            EMACSDIR = toString src;
            DOOMDIR = "${config.xdg.configHome}/${doomDirRelative}";
            DOOMPROFILELOADFILE = "${DOOMDIR}/profiles/load.el";
            DOOMLOCALDIR = "${DOOMDIR}/local";
          };
          orgFiles = [./main.org];
          tangle = pkgs.writeShellApplication {
            name = "tangle";
            runtimeEnv = emacs.env;
            runtimeInputs = [emacs.doom];
            # NOTE it seems like I just can't use flake-nimble as a flake input? thinks nimPackages doesn't exist, even on its own pin
            # NOTE ntangle seems to overwrite generated files with overlapping blocks from different input files
            text = ''
              cd "$DOOMDIR"

              rm -f ./*.el
              echo "(doom! :lang org)" > init.el

              trap 'rm -f combined.org' EXIT
              cat ./*.org > combined.org
              doom +org tangle combined.org
            '';
          };
        };
        xdg.configFile = pipe emacs.orgFiles [
          (map (file: {
            name = "${doomDirRelative}/${baseNameOf file}";
            value.source = config.lib.file.mkOutOfStoreSymlink "${emacs.env.USERDIR}/Projects/dotfiles${removePrefix (toString inputs.self) (toString file)}";
          }))
          listToAttrs
        ];
        # TODO https://github.com/smihica/emmet-mode
        # TODO programs.emacs.plugins = with pkgs.emacsPackages; [idris-mode];
        # NOTE anything else to configure? https://github.com/idris-hackers/idris-mode
      }
      (mkIf isLinux {
        services.emacs = {
          inherit (emacs) enable;
          package = emacs.finalPackage;
          defaultEditor = config.dotfiles.editor == "emacs";
          client.enable = true;
        };
        # TODO or should I use `emacsclient --eval "(emacs-everywhere)"`
        wayland.windowManager.hyprland.settings.bind = ["$mod+CONTROL+SHIFT, return, exec, doom +everywhere"];
        # TODO should I try out exwm?
        # NOTE this guy has some example code: https://github.com/martinbaillie/dotfiles
        # services.xserver.windowManager.session = lib.singleton {
        #   name = "exwm";
        #   start = "${lib.getExe doom} run";
        # };
      })
    ]);
  };
}
