{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.direnv.enable = lib.mkEnableOption "direnv";
    config = lib.mkIf config.dotfiles.programs.direnv.enable {
      dotfiles.programs = {
        elvish.integrations = ["${lib.getExe config.programs.direnv.package} hook elvish"];
        emacs.orgFiles = [./direnv.org];
        xonsh.packages = ps: [ps.xonsh.xontribs.xonsh-direnv];
        xonsh.xontribs = ["direnv"];
      };
      home.sessionVariables.DIRENV_WARN_TIMEOUT = "10s";
      programs.direnv.enable = true;
      services.lorri = {
        enable = pkgs.stdenv.hostPlatform.isLinux;
        enableNotifications = true;
        nixPackage = config.nix.package;
      };
    };
  };
}
