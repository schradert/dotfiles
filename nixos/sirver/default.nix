{ pkgs, nix-doom-emacs, home-manager, ... }:
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
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
  virtualisation.libvirtd.enable = true;
} // (import ../../home { inherit pkgs nix-doom-emacs; })
