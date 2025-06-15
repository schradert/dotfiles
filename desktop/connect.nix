{
  dotfiles = {
    # Opens firewall
    nixos = {config, ...}: {programs.kdeconnect.enable = config.dotfiles.graphical.enable;};
    home-manager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config = lib.mkIf (config.dotfiles.profiles.client.enable && pkgs.stdenv.hostPlatform.isLinux) {
        home.packages = with pkgs; [kdePackages.kdeconnect-kde qtscrcpy];
        services.kdeconnect.enable = true;
        services.kdeconnect.indicator = true;
      };
    };
  };
}
