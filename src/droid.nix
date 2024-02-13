{
  inputs,
  nix,
  ...
}:
with nix; {
  options.droid = mkOpenModuleOption {
    description = "Specific Nix-on-Droid configurations";
  };
  options.flake = mkSubmoduleOptions {
    droidModules = mkOpenModuleOption {
      description = mkDoc "Nix-on-Droid modules";
    };
  };
  config.flake.droidModules.default = {
    environment.etcBackupExtension = ".bak";
    home-manager.backupFileExtension = "hm-bak";
    home-manager.config = {
      imports = attrValues inputs.self.homeModules;
      # TODO what's the right user name and location?
      # home.username = "termux";
      # home.userDirectory = "/data/data/com.termux.nix/files/home";
    };
    home-manager.useGlobalPkgs = true;
    system.stateVersion = "23.05";
  };
  config.flake.nixOnDroidConfigurations = mapAttrs' (_: module:
    inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      modules = attrValues inputs.self.systemModules ++ attrValues inputs.self.droidModules ++ [module];
    });
}
