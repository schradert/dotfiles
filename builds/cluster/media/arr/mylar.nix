{
  # TODO implement this
  # https://github.com/mylar3/mylar3
  canivete.deploy.nixos.homeModules.reading = {config, lib, pkgs, ...}: {
    options.dotfiles.profiles.reading.enable = lib.mkEnableOption "reading apps";
    config = lib.mkIf config.dotfiles.profiles.reading.enable {
      # TODO how doe these compare with https://github.com/miru-project/miru-app
      home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs; [koreader venera]);
    };
  };
}
