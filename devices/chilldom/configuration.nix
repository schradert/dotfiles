{ config, lib, nixpkgs, home-manager, nix-doom-emacs, system, ... }:
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      (self: super: {
        tmux = super.tmux.overrideAttrs (_: {
          version = "unstable-2023-04-06";
          src = super.fetchFromGitHub {
            owner = "tmux";
            repo = "tmux";
            rev = "b9524f5b72d16bd634fc47ad1a4a9d3240bd4370";
            sha256 = lib.fakeSha256;
          };
        });
        tmuxPlugins = super.tmuxPlugins // {
          dracula = super.tmuxPlugins.dracula.overrideAttrs (_: {
            version = "unstable-2023-04-04";
            src = super.fetchFromGitHub {
              owner = "dracula";
              repo = "tmux";
              rev = "b346d1030696620154309f71d5b14bc657294a98";
              sha256 = "89S8LHTx2gYWj+Ejws5f6YRQgoj0rYE7ITtGtZibl30=";
            };
          });
        };
      })
    ];
  };
  me = { packages = with pkgs; [ bitwarden firefox ]; groups = [ "networkmanager" ]; };
in
{
  imports = [
    home-manager.nixosModule
    ./hardware-configuration.nix
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
} // (import ../../home/home.nix { inherit pkgs nix-doom-emacs me; })
