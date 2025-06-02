{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.workstation.enable {
      home.packages = [pkgs.tftui];
      programs.pug.enable = true;
    };
  };
}
