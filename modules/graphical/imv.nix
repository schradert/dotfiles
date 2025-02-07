{
  canivete.deploy.nixos.homeModules.imv = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf;
  in {
    options.dotfiles.programs.imv.enable = mkEnableOption "imv image viewer";
    config = mkIf config.dotfiles.programs.imv.enable {
      programs.imv.enable = true;
      programs.imv.settings.aliases = {
        h = "prev 1";
        l = "next 1";
        j = "zoom 10%";
        k = "zoom -10%";
        z = "zoom actual";
        _ = "flip vertical";
        "|" = "flip horizontal";
        w = "pan 0 -100";
        a = "pan -100 0";
        s = "pan 0 100";
        d = "pan 100 0";
        o = "overlay";
      };
    };
  };
}
