{ config, pkgs, ... }:
{
  environment.systemPackages = [];
  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  system.stateVersion = 4;
}
