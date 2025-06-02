{
  perSystem.canivete.pre-commit.settings.hooks.typos.settings.ignored-words = ["serie"];
  dotfiles.home-manager = {
    canivete,
    config,
    flake,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) fileContents mapAttrs mkIf mkEnableOption mkMerge setAttrByPath;
    inherit (config) dotfiles home;
    my = flake.config.canivete.meta.people.users.${home.username};
    key = fileContents (flake.inputs.self + "/.canivete/sops/${home.username}.pub");
  in {
    options.dotfiles.programs.git.enable = mkEnableOption "Git configuration";
    config = mkIf dotfiles.programs.git.enable (mkMerge [
      {
        # TODO how good is gitu vs magit vs lazygit vs tig vs code-maat vs serie?
        home.packages = with pkgs; [code-maat lazygit tig gitu gitui serie];
        programs = {
          git = {
            enable = true;
            userName = my.name;
            userEmail = my.profiles.${config.dotfiles.profile}.email;
            aliases.stash = "stash --all";
            delta.enable = true;
            # TODO find out what delta options I like the most
            # TODO how does this compare to diff-so-fancy or difftastic
            delta.options = {};
            # TODO should I use git large file storage or prefer a different strategy?
            lfs.enable = false;
            extraConfig = mkMerge [
              (mapAttrs (_: setAttrByPath ["user"]) my.accounts)
              {
                branch.sort = "-committerdate";
                color.status = "always";
                column.ui = "auto";
                # FIXME why is nix-inspect failing with core.fsmonitor?
                # core.fsmonitor = true;
                core.hooksPath = "${config.xdg.stateHome}/git/hooks";
                core.untrackedCache = true;
                fetch.writeCommitGraph = true;
                init.defaultBranch = "trunk";
                push.autoSetupRemote = true;
                rebase.autoSquash = true;
                rebase.autoStash = true;
                rebase.updateRefs = true;
                rerere.enabled = true;
              }
              {
                # Maintenance
                maintenance.auto = false;
                maintenance.strategy = "incremental";
                # TODO convert this into something dynamic, maybe project devshell basis?
                # TODO run `git maintenance start` in all of these repositories
                # TODO convert repositories to modules, maybe with categories?
                maintenance.repo = builtins.map (canivete.prefix "${home.homeDirectory}/Projects/") ["dotfiles" "sage" "alexandria" "basement" "canivete" "umomi" "VILF" "dyspraxis" "sandbox" "sabedoria"];
              }
            ];
          };
          git-cliff.enable = true;
          # TODO figure out how to use git-cliff and find what settings I prefer
          git-cliff.settings = {};
          zsh.initExtra = ''
            # disable sort when completing `git checkout`
            zstyle ':completion:*:git-checkout:*' sort false
          '';
        };
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
    ]);
  };
}
