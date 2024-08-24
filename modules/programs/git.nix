{
  canivete.deploy.system.homeModules.git = {
    config,
    flake,
    nix,
    pkgs,
    ...
  }:
    with nix; let
      inherit (config.home) username homeDirectory;
      my = flake.config.canivete.people.users.${username};
      key = readFile (flake.inputs.self + "/.canivete/sops/${username}.pub");
    in {
      dotfiles.zsh.initExtraLines = optional config.programs.git.enable ''
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
      '';
      programs.git = let
      in {
        enable = true;
        userName = my.name;
        userEmail = my.profiles.${config.dotfiles.profile}.email;
        delta.enable = true;
        # TODO find out what delta options I like the most
        # TODO how does this compare to diff-so-fancy or difftastic
        delta.options = {};
        # TODO should I use git large file storage or prefer a different strategy?
        lfs.enable = false;
        extraConfig = mkMerge [
          (mapAttrs (_: setAttrByPath ["user"]) my.accounts)
          {
            push.autoSetupRemote = true;
            color.status = "always";
            init.defaultBranch = "trunk";
            rerere.enabled = true;
            column.ui = "auto";
            branch.sort = "-committerdate";
            fetch.writeCommitGraph = true;
            core.untrackedCache = true;
            core.fsmonitor = true;
            rebase.autoSquash = true;
            rebase.autoStash = true;
            rebase.updateRefs = true;
            maintenance.auto = false;
            maintenance.strategy = "incremental";
            # TODO run `git maintenance start` in all of these repositories
            # TODO convert repositories to modules, maybe with categories?
            maintenance.repo = map (prefix "${homeDirectory}/") ["dotfiles" "sage" "alexandria" "basement" "canivete" "umomi" "VILF" "dyspraxis" "sandbox" "sabedoria"];

            # Signing
            user.signingKey = key;
            gpg.format = "ssh";
            gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
            gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowed_signers" "* ${key}");
            commit.gpgSign = true;
            tag.gpgSign = true;
            push.gpgSign = "if-asked";
          }
        ];
        aliases.stash = "stash --all";
      };
      programs.gh = {
        enable = true;
        settings.editor = config.dotfiles.editor;
        settings.git_protocol =
          if config.programs.ssh.enable
          then "ssh"
          else "https";
        settings.aliases.co = "pr checkout";
      };
      programs.gh-dash.enable = true;
      programs.git-cliff.enable = true;
      # TODO figure out how to use git-cliff and find what settings I prefer
      programs.git-cliff.settings = {};
    };
}
