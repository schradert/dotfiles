{
  dotfiles = {
    # Opens firewall
    nixos = {config, ...}: {programs.kdeconnect.enable = config.dotfiles.graphical.enable;};
    system.homeModules.connect = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf (config.dotfiles.graphical.enable && pkgs.stdenv.hostPlatform.isLinux) {
        home.packages = with pkgs; [kdePackages.kdeconnect-kde qtscrcpy];
        services.kdeconnect.enable = true;
        services.kdeconnect.indicator = true;
      };
    };
  };
}
