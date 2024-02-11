{
  flake.homeModules.git = {
    config,
    flake,
    lib,
    nix,
    ...
  }:
    with nix; {
      programs.git = {
        enable = true;
        userName = flake.config.people.my.name;
        userEmail = flake.config.people.my.email;
        extraConfig = {
          push.autoSetupRemote = true;
          color.status = "always";
          github.user = "schradert";
          gitlab.user = "schrader.tristan";
        };
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
