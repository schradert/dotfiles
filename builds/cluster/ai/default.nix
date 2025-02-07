{
  canivete.deploy.system.homeModules.ai = {config, lib, pkgs, ...}: {
    options.dotfiles.profiles.ai.enable = lib.mkEnableOption "AI programming tools";
    config = lib.mkIf config.dotfiles.profiles.ai.enable {
      home.packages = [pkgs.nur.repos.dustinblackman.oatmeal pkgs.tenere];
    };
  };
}
