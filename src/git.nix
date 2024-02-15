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
        extraConfig =
          {
            push.autoSetupRemote = true;
            color.status = "always";
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
      programs.zsh.initExtraLines = optional config.programs.git.enable ''
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
      '';
    };
}
