{
  # TODO configure more! https://github.com/xxh/xxh
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles.programs) xxh;
  in {
    options.dotfiles.programs.xxh = {
      enable = lib.mkEnableOption "xxh";
      package = lib.mkPackageOption pkgs "xxh" {};
    };
    config = lib.mkIf xxh.enable {
      home.packages = [xxh.package];
    };
  };
}
