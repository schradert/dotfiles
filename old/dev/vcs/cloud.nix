{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.programs.git.enable {
      home.packages = [pkgs.glab];
      programs.gh = {
        enable = true;
        settings.editor = config.dotfiles.editor;
        settings.git_protocol = "ssh";
        settings.aliases.co = "pr checkout";
      };
      programs.gh-dash.enable = true;
    };
  };
}
