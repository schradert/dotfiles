{
  dotfiles.home-manager = {pkgs, ...}: {
    home.packages = [pkgs.dig];
  };
}
