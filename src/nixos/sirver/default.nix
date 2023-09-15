{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "sirver";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "22.11";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment = { pathsToLink = [ "/share/zsh" ]; shells = [ pkgs.zsh ]; };
  programs = {
    git = { enable = true; config.init.defaultBranch = "trunk"; };
    htop.enable = true;
    tmux.enable = true;
    ssh.startAgent = true;
    zsh.enable = true;
  };
  security = {
    polkit.enable = true;
    pam.enableSSHAgentAuth = true;
  };
  services.openssh.enable = true;
  users.users.tristan = {
    isNormalUser = true;
    home = "/home/tristan";
    description = "Tristan Schrader";
    extraGroups = [ "wheel" "tty" "libvirtd" ];
    shell = pkgs.zsh;
  };
  virtualisation.libvirtd.enable = true;
}
