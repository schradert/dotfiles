{
  # TODO which one should I use?
  # TODO configure qbittorrent in mixed mode
  # TODO activate SAM protocol and follow i2pd docs
  # TODO how to get I2P+ (prettiest frontend) https://i2pplus.github.io/
  canivete.deploy.system.homeModules.i2p = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.dotfiles.programs.i2p.enable = lib.mkEnableOption "I2P router";
    config = lib.mkIf config.dotfiles.programs.i2p.enable {
      home.packages = [pkgs.i2pd];
    };
  };
}
