{self, ...}:
{
  flake = {
    droidModules.common = {
      environment.etcBackupExtension = ".bak";
      home-manager.backupFileExtension = "hm-bak";
      home-manager.config = {
        imports = [self.homeModules.common];
        # TODO what's the right user name and location?
        # home.username = "termux";
        # home.userDirectory = "/data/data/com.termux.nix/files/home";
        programs.eza.enable = null;
        programs.exa.enable = true;
      };
      home-manager.useGlobalPkgs = true;
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';
      system.stateVersion = "23.05";
    };
  };
}
