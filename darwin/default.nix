{ config, lib, pkgs, ... }:
{
  imports = [ ];

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = 4;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment = { pathsToLink = [ "/share/zsh" ]; shells = [ pkgs.zsh ]; };
  services.nix-daemon.enable = true;
}
