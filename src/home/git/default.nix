{
  config,
  flake,
  ...
}: {
  programs.git = {
    enable = true;
    # TODO (Tristan): figure out using home.username
    userName = flake.config.people.my.name;
    userEmail = flake.config.people.my.email;
    extraConfig = {
      push.autoSetupRemote = true;
      color.status = "always";
      github.user = "schradert";
      gitlab.user = "schrader.tristan";
      # This is probably how our hosted Gitea repository will look
      # gitea.git.bunkbed.tech.user = "tristan";
    };
  };
  programs.gh = {
    enable = true;
    settings.editor = "emacs";
    settings.git_protocol = "ssh";
    #   settings.editor = lib.mkIf config.programs.emacs.enable "emacs";
    #   settings.git_protocol = lib.mkIf config.programs.ssh.enable "ssh";
    settings.aliases.co = "pr checkout";
  };
}
