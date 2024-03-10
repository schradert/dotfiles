{
  flake.homeModules.git = {
    config,
    flake,
    lib,
    nix,
    ...
  }:
    with nix; {
      programs.git = let
        my = flake.config.people.users.${config.home.username};
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
        extraConfig =
          {
            push.autoSetupRemote = true;
            color.status = "always";
            init.defaultBranch = "trunk";
          }
          // mapAttrs (_: setAttrByPath ["user"]) my.accounts;
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
      programs.git-cliff.enable = true;
      # TODO figure out how to use git-cliff and find what settings I prefer
      programs.git-cliff.settings = {};
      programs.zsh.initExtraLines = optional config.programs.git.enable ''
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
      '';
    };
}
