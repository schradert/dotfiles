{ config, lib, pkgs, nix-doom-emacs, home-manager }:
{
  imports = [ home-manager.darwinModules.home-manager ];
  environment.systemPackages = [ ];
  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  system.stateVersion = 4;
}
