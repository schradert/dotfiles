{
  dotfiles.home-manager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles) graphical;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
  in {
    options.dotfiles.graphical.wireless.enable = mkEnableOption "wireless network management";
    config = mkIf graphical.wireless.enable {
      assertions = toList {
        assertion = graphical.enable;
        message = "Wireless network management is for graphical nodes";
      };
      home.packages = with pkgs;
        mkMerge [
          [bandwhich]
          (mkIf stdenv.hostPlatform.isLinux [
            airgeddon
            blueman
            bluetui
            impala
            overskride
          ])
        ];
      # TODO build https://github.com/dmtrKovalenko/blendr or https://github.com/ztroop/btlescan
    };
  };
}
