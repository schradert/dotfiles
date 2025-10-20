{
  dotfiles.home-manager = {config, perSystem, ...}: {
    programs.helix = {
      enable = true;
      defaultEditor = config.dotfiles.editor == "hx";
      package = perSystem.inputs'.helix.packages.default;
    };
  };
}
