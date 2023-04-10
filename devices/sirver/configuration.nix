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
in
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
} // (import ../../home/home.nix { inherit pkgs nix-doom-emacs; })
