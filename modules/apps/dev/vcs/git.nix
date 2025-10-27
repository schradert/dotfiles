{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete.meta.people) users;
in {
  dotfiles.devenv.git-hooks.hooks.typos.settings.ignored-words = ["serie"];
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) fileContents mkIf mkMerge setAttrByPath;
    inherit (config.home) username;
    my = users.${username};
    inherit (my.profiles.${config.dotfiles.profile}) email;
    key = fileContents (inputs.self + "/.canivete/sops/${username}.pub");
  in {
    config = mkIf config.dotfiles.profiles.client.workstation.enable (mkMerge [
      {
        home.packages = with pkgs; [code-maat tig gitu serie];
        programs = {
          git = {
            enable = true;
            userName = my.name;
            userEmail = email;
            aliases.stash = "stash --all";
            delta.enable = true;
            delta.options = {
              diff-so-fancy = true;
              hyperlinks = true;
              line-numbers = true;
            };
            extraConfig = mkMerge [
              (builtins.mapAttrs (_: setAttrByPath ["user"]) my.accounts)
              {
                branch.sort = "-committerdate";
                # color.status = "always";
                column.ui = "auto";
                # TODO why is nix-inspect failing with core.fsmonitor?
                # core.fsmonitor = true;
                core.hooksPath = "${config.xdg.stateHome}/git/hooks";
                core.untrackedCache = true;
                diff.noprefix = true;
                fetch.writeCommitGraph = true;
                init.defaultBranch = "trunk";
                maintenance.auto = false;
                maintenance.strategy = "incremental";
                push.autoSetupRemote = true;
                rebase.autoSquash = true;
                rebase.autoStash = true;
                rebase.updateRefs = true;
                rerere.enabled = true;
              }
            ];
          };
          gitui.enable = true;
          lazygit.enable = true;
          lazygit.settings.git.paging.pager = "delta --paging=never --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
          zsh.initContent = ''
            # disable sort when completing `git checkout`
            zstyle ':completion:*:git-checkout:*' sort false
          '';
        };
      }
      {
        # Cloud
        home.packages = [pkgs.glab];
        programs.gh = {
          enable = true;
          extensions = with pkgs; [
            gh-f
            gh-poi
            gh-gei
            gh-eco
            gh-notify
            gh-skyline
            gh-signoff
          ];
          settings.editor = config.dotfiles.editor;
          settings.git_protocol = "ssh";
          settings.aliases.co = "pr checkout";
        };
        programs.gh-dash.enable = true;
      }
      {
        # Signing
        programs.gpg.enable = true;
        programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";
        programs.git.extraConfig = {
          user.signingKey = key;
          gpg.format = "ssh";
          gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
          gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowed_signers" "* ${key}");
          commit.gpgSign = true;
          tag.gpgSign = true;
          push.gpgSign = "if-asked";
        };
      }
      {
        # Theme
        # NOTE stylix doesn't support git
        programs.git.extraConfig.color = {
          ui = "auto";
          branch = {
            current = "cyan bold reverse";
            local = "white";
            plain = "";
            remote = "cyan";
          };
          diff = {
            commit = "";
            func = "cyan";
            plain = "";
            whitespace = "magenta reverse";
            meta = "white";
            frag = "cyan bold reverse";
            old = "red";
            new = "green";
          };
          grep = {
            context = "";
            filename = "";
            function = "";
            linenumber = "white";
            match = "";
            selected = "";
            separator = "";
          };
          interactive = {
            error = "";
            header = "";
            help = "";
            prompt = "";
          };
          status = {
            added = "green";
            changed = "yellow";
            header = "";
            localBranch = "";
            nobranch = "";
            remoteBranch = "cyan bold";
            unmerged = "magenta bold reverse";
            untracked = "red";
            updated = "green bold";
          };
        };
      }
      {
        # Emacs
        sops.secrets.github = {};
        sops.secrets.gitlab = {};
        sops.templates.authinfo.content = lib.mkMerge [
          "machine api.github.com login ${email}^code-review password ${config.sops.placeholder.github}"
          "machine api.gitlab.com login ${email}^code-review password ${config.sops.placeholder.gitlab}"
        ];
        programs.doom-emacs = {
          extraPackages = e: [e.magit-todos];
          tangle.init = {
            tools.magit = ["+forge"];
            ui.vc-gutter = ["+pretty"];
          };
          tangle.config = ''
            (setq! user-full-name "${my.name}"
                   user-mail-address "${email}")
            (after! magit
              (magit-todos-mode 1)
              (setq! magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")
                     magit-diff-refine-hunk 'all))
            (after! code-review
              (setq! code-review-fill-column 80
                     code-review-auth-login-marker 'forge)
              (map! :after forge
                    :map forge-topic-mode-map
                    "rr" #'code-review-forge-pr-at-point)
              ;; Show *Code Review* in current workspace (Doom bug)
              (add-hook! code-review-mode (lambda () (persp-add-buffer (current-buffer))))
              (add-hook! code-review-mode #'emojify-mode))
          '';
        };
      }
    ]);
  };
}
