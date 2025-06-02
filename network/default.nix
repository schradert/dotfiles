{
  dotfiles.home-manager = {pkgs, ...}: {
    home.packages = with pkgs; [
      rustscan
      speedtest-cli
    ];
  };
}
