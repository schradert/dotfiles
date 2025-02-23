{
  canivete.deploy.system.homeModules.helix = {
    config,
    lib,
    perSystem,
    ...
  }: {
    config = lib.mkIf config.programs.helix.enable {
      # TODO how does this compare to vim? binary size? extensions? bugs?
      programs.helix = {
        package = perSystem.inputs'.helix.packages.default;
        defaultEditor = config.dotfiles.editor == "hx";
      };
    };
  };
}
