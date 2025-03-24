{
  # TODO https://github.com/iv-org/invidious
  # TODO https://github.com/TeamPiped/Piped
  # NOTE might need to work with both...
  # NOTE also it's possible I need Cloudflare WARP? or is my tunnel good enough?
  canivete.deploy.system.homeModules.invidious = {config, lib, pkgs, ...}: {
    home.packages = lib.mkIf config.dotfiles.workstation.enable [pkgs.invidtui];
  };
}
