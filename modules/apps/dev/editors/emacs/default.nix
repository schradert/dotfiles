{
  dotfiles.nixos = {flake, ...}: {
    nixpkgs.overlays = [flake.inputs.emacs-overlay.overlay];
    dotfiles.nixpkgs.config.allowUnfreePackages = ["aspell-dict-en-science"];
  };
  dotfiles.home-manager = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      flake.inputs.nix-doom-emacs-unstraightened.homeModule
      ({canivete, ...}: let
        inherit (builtins) concatStringsSep;
        inherit (canivete) mkNullableOption;
        inherit (config.programs) doom-emacs;
        inherit (lib) mapAttrsToList mkDefault mkIf types;
        surround = target: value: concatStringsSep "\n" ["#+begin_src emacs-lisp ${target}" value "#+end_src"];

        # NOTE borrowed upstream from nix-doom-emacs-unstraightened
        # Convert a Nix expression to a `doom!` block suitable for init.el.
        #
        # Input: a nested attribute set.
        # The keys of the first level are categories (like `lang`).
        # The keys of the second level are module names (like `nix`).
        # The values are lists of module flags, or `true` for no flags.
        toInit = attrs:
          lib.concatLines (
            ["(doom!"]
            ++ (mapAttrsToList (
                cat: modules: (lib.concatLines (
                  [(":" + cat)]
                  ++ (mapAttrsToList (
                    mod: value:
                      if value == true
                      then mod
                      else if builtins.isList value
                      then "(${mod} ${concatStringsSep " " value})"
                      else abort "${lib.toPretty value} not supported"
                  ))
                  modules
                ))
              )
              attrs)
            ++ [")"]
          );
      in {
        options.programs.doom-emacs = {
          files = canivete.mkAttrsOption (with types; either str path) {description = "Extra config files";};
          _tangleArgs = mkNullableOption (types.separatedString " ") {description = "Tangling args";};
          tangle = lib.mkOption {
            default = {};
            type = types.submodule ({config, ...}: {
              options = {
                init = mkNullableOption (with types; attrsOf (attrsOf (either bool (listOf str)))) {};
                raw = mkNullableOption types.lines {};
                config = mkNullableOption types.lines {};
                packages = mkNullableOption types.lines {};
              };
              config = lib.mkMerge [
                (mkIf (config.config != null) {raw = surround ":tangle config.el" config.config;})
                (mkIf (config.packages != null) {raw = surround ":tangle packages.el" config.packages;})
                (mkIf (config.init != null) {
                  raw = surround ":tangle init.el" (concatStringsSep "\n" [
                    # Only seems to work if :app and :config sections are at the end...
                    (toInit (removeAttrs config.init ["app" "config"]))
                    "(doom! :os (:if (featurep :system 'macos) macos))"
                    (toInit {inherit (config.init) app config;})
                  ]);
                })
              ];
            });
          };
        };
        config = lib.mkMerge [
          {
            programs.doom-emacs.extraBinPackages = with config.programs; [
              ripgrep.package
              git.package
              fd.package
            ];
            programs.doom-emacs.doomDir = lib.pipe doom-emacs.files [
              (mapAttrsToList (name: source: ''
                mkdir -p "$out/$(dirname "${name}")"
                ${
                  if builtins.isPath source || lib.isStorePath source
                  then "cp -rL ${source} \"$out/${name}\""
                  else "echo ${lib.escapeShellArg source} > \"$out/${name}\""
                }
              ''))
              (concatStringsSep "\n")
              (pkgs.runCommand "doom-config" {})
              mkDefault
            ];
          }
          (mkIf (doom-emacs.tangle != null) {
            programs.doom-emacs = {
              files."tangle.org" = mkDefault doom-emacs.tangle.raw;
              _tangleArgs = mkDefault "tangle.org";
              tangleArgs = mkDefault doom-emacs._tangleArgs;
            };
          })
        ];
      })
    ];
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      # fonts only detected in home.packages
      home.packages = [pkgs.nerd-fonts.symbols-only];
      sops.templates.authinfo = {};
      # services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      #   emacs = {
      #     inherit (emacs) enable;
      #     package = emacs.finalPackage;
      #     defaultEditor = config.dotfiles.editor == "emacs";
      #     client.enable = true;
      #   };
      # };
      # TODO or should I use `emacsclient --eval "(emacs-everywhere)"`
      # wayland.windowManager.hyprland.settings.bind = ["$mod+CONTROL+SHIFT, return, exec, doom +everywhere"];
      programs.doom-emacs = lib.mkMerge [
        {
          enable = true;
          doomLocalDir = "${config.xdg.configHome}/doom/local";
          emacs = pkgs.emacs-unstable-nox;
          extraBinPackages = [pkgs.sqls];
          tangle.raw = lib.mkMerge [
            # Taken from https://www.reddit.com/r/DoomEmacs/comments/1dohgxv/gitsavannahgnuorg_is_down/
            ''
              #+begin_src emacs-lisp :tangle no
              (defadvice! straight-use-recipes-ignore-nongnu-elpa-a (fn recipe)
                :around #'straight-use-recipes
                (unless (eq 'nongnu-elpa (car recipe))
                  (funcall fn recipe)))
              #+end_src
            ''
          ];
          tangle.config = ''
            (setq!
              auth-sources '(("${config.sops.templates.authinfo.path}"))
              delete-by-moving-to-trash t
              trash-directory (concat (getenv "USERDIR") "/.Trash"))
          '';
          tangle.init = {
            checkers.syntax = ["+childframe" "+flymake" "+icons"];
            completion.corfu = ["+icons" "+orderless" "+dabbrev"];
            completion.vertico = ["+childframe" "+icons"];
            config.default = ["+bindings"];
            editor = {
              evil = ["+everywhere"];
              file-templates = true;
              fold = true;
              format = ["+onsave" "+lsp"];
              # TODO god = true;
              lispy = true;
              multiple-cursors = true;
              objed = ["+manual"];
              rotate-text = true;
              snippets = true;
              word-wrap = true;
            };
            emacs = {
              electric = true;
              eww = true;
              ibuffer = ["+icons"];
              undo = ["+tree"];
              vc = true;
            };
            input.layout = true;
            lang.data = true;
            lang.emacs-lisp = true;
            lang.json = ["+lsp" "+tree-sitter"];
            os.tty = ["+osc"];
            tools = {
              eval = ["+overlay"];
              pdf = true;
              lsp = ["+peek"];
              upload = true;
            };
            ui = {
              doom-dashboard = true;
              doom-quit = true;
              emoji = ["+ascii" "+github" "+unicode"];
              hl-todo = true;
              ligatures = ["+extra"];
              minimap = true;
              modeline = true;
              nav-flash = true;
              ophints = true;
              popup = ["+all" "+defaults"];
              smooth-scroll = ["+interpolate"];
              tabs = true;
              unicode = true;
              vi-tilde-fringe = true;
              window-select = ["+switch-window"];
              workspces = true;
              zen = true;
            };
          };
        }
        {
          extraBinPackages = with pkgs; [coreutils-prefixed imagemagick ffmpegthumbnailer mediainfo poppler unzip];
          tangle.init.emacs.dired = ["+dirvish" "+icons"];
          # TODO is dired-preview necessary or useful?
          # extraPackages = e: [e.dired-preview];
          # tangle.config = "(use-package! dired-preview :init (dired-preview-global-mode 1))";
        }
        {
          extraPackages = e: [e.imenu-list];
          tangle.config = ''
            (after! imenu-list
                    (map! :leader :desc "imenu-list-toggle" "b L" #'imenu-list-smart-toggle))
          '';
        }
        {
          extraPackages = e: with e; [org-ql org-super-agenda org-timeline org-roam-ui];
          extraBinPackages = with pkgs; [gnuplot sqlite maim];
          tangle.raw = builtins.readFile ./org.org;
          tangle.init = {
            lang.org = ["+brain" "+contacts" "+dragndrop" "+crypt" "+gnuplot" "+journal" "+noter" "+pandoc" "+passwords" "+pomodoro" "+present" "+pretty" "+roam2"];
            tools.pdf = true;
            ui.deft = true;
          };
        }
        {
          tangle.init.checkers.grammar = true;
          # TODO run languagetool server
          extraBinPackages = [pkgs.languagetool];
        }
        {
          tangle.init.checkers.spell = ["+aspell" "+everywhere" "+flyspell"];
          extraBinPackages = [(pkgs.aspellWithDicts (dicts: with dicts; [ar de en es fi fr la pt_BR pt_PT ru tr en-computers en-science]))];
        }
        {
          tangle.init.editor.parinfer = true;
          extraBinPackages = [pkgs.parinfer-rust-emacs];
        }
        {
          tangle.init.lang.yaml = ["+lsp" "+tree-sitter"];
          extraBinPackages = [pkgs.yaml-language-server];
        }
        {
          tangle.init.tools.collab = ["+tunnel"];
          extraBinPackages = [pkgs.tuntox];
        }
        {
          tangle.init.tools.debugger = true;
          # TODO get other debuggers in
          extraBinPackages = [pkgs.gdb];
        }
        {
          tangle.init.tools.lookup = ["+dictionary" "+docsets" "+offline"];
          tangle.config = ''
            (after! lookup
              (add-to-list '+lookup-provider-url-alist
                           '("Wiktionary" . "${"https"}://en.wiktionary.org/wiki/%s")))
          '';
          extraBinPackages = [config.programs.ripgrep.package pkgs.sqlite pkgs.wordnet];
        }
        {
          tangle.init.ui.doom = true;
          tangle.config = "(setq doom-theme 'doom-dracula)";
        }
        {
          tangle.init.ui.treemacs = ["+lsp"];
          tangle.config = "(setq +treemacs-git-mode 'deferred)";
          extraBinPackages = [pkgs.python3];
        }
        {
          # TODO does this even work without X libraries?
          tangle.init.app.everywhere = true;
          extraBinPackages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
            # NOTE wayland substitutes
            # wl-clipboard-rs
            # wtype, ydotool, wlrctl
            # wlprop
            # ???
            xclip
            xdotool
            xorg.xprop
            xorg.xwininfo
          ]);
        }
        {
          tangle.init.tools.tree-sitter = true;
          tangle.config = "(setq! +tree-sitter-hl-enabled-modes t)";
        }
        {
          tangle.init.lang.web = ["+lsp" "+tree-sitter"];
          extraBinPackages = [pkgs.html-tidy];
        }
      ];
    };
  };
}
