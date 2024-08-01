{nix, ...}: {
  canivete.deploy.droid.modules.default = {
    config,
    options,
    ...
  }: {
    environment.etcBackupExtension = ".bak";
    home-manager = {
      backupFileExtension = "hm-bak";
      useGlobalPkgs = true;
      sharedModules = nix.toList {
        options.dotfiles = options.dotfiles;
        config.dotfiles = config.dotfiles;
      };
    };
    system.stateVersion = "23.05";
  };
}
