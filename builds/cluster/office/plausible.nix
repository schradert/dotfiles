{
  # TODO https://github.com/plausible/analytics
  # TODO or alternative https://github.com/matomo-org/matomo
  canivete.deploy.system.homeModules.conclusive = {
    config,
    lib,
    ...
  }: {
    options.dotfiles.programs.conclusive.enable = lib.mkEnableOption "conclusive";
    config = lib.mkIf config.dotfiles.programs.conclusive.enable {
      # TODO build https://github.com/mrusme/conclusive
      # home.packages = [pkgs.conclusive];
    };
  };
}
