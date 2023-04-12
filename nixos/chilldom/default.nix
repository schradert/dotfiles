{ pkgs, nix-doom-emacs, home-manager, ... }:
let
  me = { packages = with pkgs; [ bitwarden firefox ]; groups = [ "networkmanager" ]; };
in
{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.hostName = "chilldom";
  networking.wireless.enable = true;
  networking.wireless.networks = { lanyard = { psk = "bruhWHY123!"; }; };

  fonts.fonts = with pkgs; [ meslo-lgs-nf ];
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.openssh.enable = true;

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
  security = { polkit.enable = true; pam.enableSSHAgentAuth = true; };
  users.mutableUsers = true;
  virtualisation = {
    libvirtd.enable = true;
    podman = { enable = true; dockerSocket.enable = true; defaultNetwork.settings.dns_enable = true; };
  };
} // (import ../../home { inherit pkgs nix-doom-emacs me; })
