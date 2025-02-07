{
  # TODO https://github.com/AdguardTeam/AdGuardHome
  canivete.deploy.system.homeModules.adguard = {config, lib, pkgs, ...}: {
    options.dotfiles.programs.adguardian.enable = lib.mkEnableOption "adguardian";
    config = lib.mkIf config.dotfiles.programs.adguardian.enable {
      home.packages = [pkgs.adguardian];
    };
  };
}
