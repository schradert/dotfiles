{
  flake.homeModules.wtf = {
    config,
    lib,
    nix,
    pkgs,
    ...
  }: {
    options.programs.wtf.enable = lib.mkEnableOption "wtfutil";
    config = lib.mkIf config.programs.wtf.enable {
      home.packages = [pkgs.wtf];
      programs.zsh.initExtraLines = nix.toList "export PATH=\"$PATH:$HOME/.config/wtf\"";
      # TODO add the configuration
    };
  };
}
