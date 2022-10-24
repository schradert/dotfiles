{ config, pkgs, ... }:
let
  inherit (pkgs.lib) attrNames zipAttrsWith id;
  regularUsers = [];
  adminUsers = [ { tristan = "Tristan Schrader"; } ];
  usePodman = false;
in {
  imports = [ ./hardware-configuration.nix <home-manager/nixos> ];

  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;
#  boot.loader.grub = {
#    enable = true;
#    version = 2;
#    enableCryptodisk = true;
#    device = "/dev/sda";
#  };

  environment = {
    pathsToLink = [ "/share/zsh" ];
    systemPackages = with pkgs; [
      aria2  # downloading anything
      bash
      iftop
      cachix
      curl
      file
      git
      google-cloud-sdk
      htop
      imagemagick  # image processor CLI
      inotify-tools  # easy 'inotify' interface
      iotop  # process I/O analyzer
      lsof  # list open files
      nethogs  # process bandwidth analyzer
      nix-prefetch-scripts
      nmap
      openssl
      ranger
      rclone
      tig
      tmux
      tree
      unzip
      vim
      wget
      zip
      zsh
    ] ++ (if usePodman then with pkgs; [ arion docker-client ] else []);
  }; 
  fonts.fonts = with pkgs; [ meslo-lgs-nf ];
  i18n.defaultLocale = "en_US.UTF-8";
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    hostName = "server";
#    networkmanager.enable = true;
#    wireless.enable = true;
  };
  nix = {
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  programs.mosh.enable = true;  # ssh optimized for bad connection
  security.sudo.enable = true;
  services = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    openssh = {
      enable = true;
      gatewayPorts = "yes";
    };
    xserver.enable = true;
  };
  system.stateVersion = "22.05";
  time.timeZone = "America/Los_Angeles";
  users = {
    extraUsers =
      let
        mkUser = type: username: fullname: {
          isNormalUser = true;
          home = "/home/${username}";
          description = fullname;
          extraGroups = ([]
          ++ (if type == "regular" then [] else [ "wheel" ])
          ++ (if usePodman then [ "podman" ] else [ "docker" ])
          );
          openssh.authorizedKeys.keyFiles = [ "/etc/nixos/${type}-users/${username}.pub" ];
        };
      in
        (zipAttrsWith (mkUser "regular") regularUsers) //
        (zipAttrsWith (mkUser "admin") adminUsers);
    mutableUsers = true;
    users.tristan.shell = pkgs.zsh;
  };
  virtualisation.docker = {
    enable = true;
    liveRestore = true;
  };
} //
(if usePodman then {
  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;
    };
  };
} else {
  virtualisation.docker = {
    enable = true;
    liveRestore = true;
  };
})
