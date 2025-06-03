{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) recursiveUpdate toList;
  # Disko does not actually merge NixOS modules (major bummer!)
  # I have to use recursiveUpdate within the same module for all settings to be detected and used
  # NOTE https://github.com/nix-community/disko/issues/678
  # NOTE https://github.com/NixOS/nixpkgs/pull/284551
  disko.devices.disk.base = {
    device = "/dev/sda";
    type = "disk";
    content.type = "gpt";
    content.partitions = {
      boot = {
        priority = 1;
        type = "EF02";
        size = "1M";
      };
      ESP = {
        priority = 2;
        type = "EF00";
        size = "512M";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = ["umask=077"];
        };
      };
      root = {
        priority = 3;
        end = "-1G";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
          # TODO where does root partition need to be resizable
          # mountOptions = ["defaults" "x-systemd.growfs"];
        };
      };
      swap = {
        size = "100%";
        content.type = "swap";
        content.discardPolicy = "both";
        content.resumeDevice = true;
      };
    };
  };
  lvmDisko = end: device:
    recursiveUpdate disko {
      devices.disk.base = {
        inherit device;
        content.partitions.root = {inherit end;};
        content.partitions.k8s = {
          priority = 3;
          end = "-1G";
          content.type = "lvm_pv";
          content.vg = "k8s";
        };
      };
      devices.lvm_vg.k8s.type = "lvm_vg";
    };
in {
  dotfiles.nodes = {
    # Driver
    falcon.system = {pkgs, ...}: {
      dotfiles.graphical.monitors = true;
      dotfiles.graphical.hyprland.enable = true;
      dotfiles.services.yubikey.enable = true;
      dotfiles.workstation.enable = true;
      boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
      disko = recursiveUpdate lvmDisko {
        devices.disk.base = {
          device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169";
          content.partitions.root.end = "-101G";
        };
      };
      home-manager.sharedModules = toList {
        dotfiles.programs.steam.external = {
          enable = true;
          srm.userAccounts = ["supertriggy"];
          runescape.runelite.enable = true;
        };
      };

      # Gaming
      programs.steam.enable = true;
      # TODO can https://github.com/luxtorpeda-dev/luxtorpeda be added?
      # TODO https://github.com/dreamer/boxtron
      programs.steam.extraCompatPackages = with pkgs; [proton-ge-bin steamtinkerlaunch steam-play-none];
      programs.steam.protontricks.enable = true;
      programs.gamemode.enable = true;
      programs.gamemode.enableRenice = true;
      services.xserver.videoDrivers = ["radeon" "i915" "displaylink" "modesetting" "fbdev"];
    };

    # Servers
    sirver.system = {
      dotfiles.profiles.server.enable = true;
      # TODO is this the best way to configure this?
      canivete.kubernetes.root = true;
      boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
      boot.kernelModules = ["kvm-intel"];
      disko = lvmDisko "-1T" "/dev/disk/by-id/scsi-361866da05a3c260002ecf1a16170342b";

      # FIXME Mini switch to connect falcon
      # networking.bridges.br0.interfaces = ["eno3" "eno4"];
      # networking.interfaces.br0.useDHCP = true;

      # TODO separate this into proper service?
      dotfiles.devops.enable = true;
    };
    bonobo.system = {
      dotfiles.profiles.server.enable = true;
      boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
      disko = lvmDisko "-51G" "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD";
    };
    chinchilla.system = {
      dotfiles.profiles.server.enable = true;
      boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
      disko = lvmDisko "-51G" "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER";
    };
    dingo.system = {
      dotfiles.profiles.server.enable = true;
      boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
      disko = recursiveUpdate lvmDisko {
        devices.disk.base = {
          device = "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL";
          content.partitions.root.end = "-51G";
        };
      };
    };
    octopus.system = {
      dotfiles.profiles.server.enable = true;
      boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid" "sr_mod"];
      boot.kernelModules = ["kvm-intel"];
      disko = lvmDisko "-1T" "/dev/disk/by-id/scsi-36b82a720cf60ce002a80577e12e4a1a7";
    };

    # Portable
    axolotl.system = {
      dotfiles.profiles.workstation.enable = true;
      dotfiles.devices.monitors.enable = true;
      dotfiles.services.yubikey.enable = true;

      # Hardware
      boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
      disko = lvmDisko "-101G" "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169";
      home-manager.sharedModules = [{dotfiles.programs.macchina.networkInterface = "enp0s31f6";}];

      # TODO Deactivate auto sleep
      services.logind.lidSwitch = "ignore";
      systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };

      # TODO is this only set for DisplayLink compatibility?
      # If so, it should probably be combined into dotfiles.devices.monitors
      services.xserver.videoDrivers = ["radeon" "i915" "displaylink" "modesetting" "fbdev"];
    };
    echidna.system = {
      imports = [inputs.nixos-wsl.nixosModules.default];
      wsl.enable = true;
      wsl.defaultUser = config.canivete.meta.people.me;
      wsl.startMenuLaunchers = true;
      # TODO figure out hardwired internet setup (switch + ethernet to usb adapters)
      # TODO should I I use wsl-vpnkit?
      # TODO value of OpenGL driver from Windows?
      # TODO any settings I should configure for more resource usage or enable graphical applications?
      # wsl.usbip.enable = true;
      # wsl.usbip.autoAttach = [];
      # wsl.usbip.snippetIpAddress = "127.0.0.1";
      # wsl.useWindowsDriver = true;
      # wsl.wslConf = {};
    };
    # NOTE remainder of configuration is in ./steam-deck.nix
    systeamadeck.system.disko = recursiveUpdate disko {devices.disk.base.device = "/dev/disk/by-id/nvme-Phison_ESMP001TMN48C3-E21TS_23445M001T05978";};
  };
}
