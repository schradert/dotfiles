{
  dotfiles.home-manager = {
    config,
    perSystem,
    ...
  }: {
    programs.helix = {
      enable = true;
      package = perSystem.inputs'.helix.packages.default;
      defaultEditor = config.dotfiles.editor == "hx";
    };
  };
}
