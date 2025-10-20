{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.client.workstation.enable {
      dotfiles.programs = {
        elvish.interactiveExtra = "eval (${lib.getExe config.programs.direnv.package} hook elvish | slurp)";
        xonsh.packages = ps: [ps.xonsh.xontribs.xonsh-direnv];
      };
      home.sessionVariables.DIRENV_WARN_TIMEOUT = "10s";
      programs.direnv.enable = true;
      programs.doom-emacs.tangle.init.tools.direnv = true;
      services.lorri = {
        enable = pkgs.stdenv.hostPlatform.isLinux;
        enableNotifications = true;
        nixPackage = config.nix.package;
      };
    };
  };
}
