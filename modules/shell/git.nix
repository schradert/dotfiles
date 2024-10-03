{
  canivete.deploy.system.homeModules.git = {
    config,
    flake,
    lib,
    nix,
    pkgs,
    ...
  }: let
    inherit (lib) fileContents mapAttrs mkIf mkEnableOption mkMerge toList setAttrByPath;
    inherit (nix) prefix;
    inherit (config) dotfiles programs home;
    my = flake.config.canivete.people.users.${home.username};
    key = fileContents (flake.inputs.self + "/.canivete/sops/${home.username}.pub");
  in {
    options.dotfiles.programs.git.enable = mkEnableOption "Git configuration";
    config = mkIf dotfiles.programs.git.enable {
      dotfiles.zsh.initExtraLines = toList ''
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
      '';
      home.packages = with pkgs; [lazygit tig];
      programs = {
        gpg.enable = true;
        git = {
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
              maintenance.repo = map (prefix "${home.homeDirectory}/") ["dotfiles" "sage" "alexandria" "basement" "canivete" "umomi" "VILF" "dyspraxis" "sandbox" "sabedoria"];

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
        gh = {
          enable = true;
          settings.editor = dotfiles.editor;
          settings.git_protocol =
            if programs.ssh.enable
            then "ssh"
            else "https";
          settings.aliases.co = "pr checkout";
        };
        gh-dash.enable = true;
        git-cliff.enable = true;
        # TODO figure out how to use git-cliff and find what settings I prefer
        git-cliff.settings = {};
      };
    };
  };
}
