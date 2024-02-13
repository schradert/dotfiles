{
  flake.homeModules.wtf = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.programs.wtf.enable = lib.mkEnableOption "wtfutil";
    config = lib.mkIf config.programs.wtf.enable {
      home.packages = [pkgs.wtf];
      home.sessionPath = ["${config.xdg.configHome}/wtf"];
      # TODO add the configuration
    };
  };
}
