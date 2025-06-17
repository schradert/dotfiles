{
  dotfiles.nixos = {pkgs, ...}: {
    documentation.dev.enable = true;
    documentation.man.generateCaches = true;
    environment.systemPackages = [pkgs.man-pages pkgs.man-pages-posix];
  };
}
