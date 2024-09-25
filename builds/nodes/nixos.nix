{
  config,
  nix,
  ...
}: with nix; let
  inherit (config.canivete) root;
  sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
  # Disko does not actually merge NixOS modules (major bummer!)
  # I have to use recursiveUpdate within the same module for all settings to be detected and used
  # NOTE https://github.com/nix-community/disko/issues/678
  # NOTE https://github.com/NixOS/nixpkgs/pull/284551
  disko.devices.disk.base = {
    device = "/dev/sda";
    type = "disk";
    content.type = "gpt";
    content.partitions = {
      ESP = {
        priority = 1;
        type = "EF00";
        size = "500M";
        content.type = "filesystem";
        content.format = "vfat";
        content.mountpoint = "/boot";
      };
      root = {
        priority = 2;
        end = "-1G";
        content.type = "filesystem";
        content.format = "ext4";
        content.mountpoint = "/";
      };
      swap = {
        size = "100%";
        content.type = "swap";
        content.discardPolicy = "both";
        content.resumeDevice = true;
      };
    };
  };
  lvmDisko = recursiveUpdate disko {
    devices.disk.base = {
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
  # TODO why the fuck do I have to keep doing this?
  perSystem.canivete.opentofu.workspaces.deploy.modules.install-override.resource.null_resource = {
    nixos_axolotl_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_bonobo_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_chinchilla_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_dingo_system_install.provisioner.local-exec.command = mkForce "echo";
    nixos_octopus_system_install.provisioner.local-exec.command = mkForce "echo";
  };
  canivete.deploy.nixos.nodes = {
    sirver = {
      install.host = "192.168.50.23";
      install.sshOptions = mkForce ["User=root"];
      target.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        dotfiles.kubernetes.root = true;
        dotfiles.devops.enable = true;
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/scsi-361866da05a3c260002ecf1a16170342b";
            content.partitions.root.end = "-1T";
          };
        };
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
        boot.kernelModules = ["kvm-intel"];
      };
    };
    axolotl = {
      install.host = "192.168.50.250";
      build.host = root;
      build.sshOptions = sshOptions;
      profiles.system.sshProtocol = "ssh";
      profiles.system.module = {
        dotfiles.graphical.enable = true;
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169";
            content.partitions.root.end = "-101G";
          };
        };
        powerManagement.cpuFreqGovernor = "powersave";
        home-manager.sharedModules = toList {dotfiles.macchina.networkInterface = "enp0s31f6";};
      };
    };
    bonobo = {
      install.host = "192.168.50.142";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    chinchilla = {
      install.host = "192.168.50.85";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    dingo = {
      install.host = "192.168.50.105";
      build.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL";
            content.partitions.root.end = "-51G";
          };
        };
      };
    };
    octopus = {
      install.host = "192.168.50.53";
      target.sshOptions = sshOptions;
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid" "sr_mod"];
        boot.kernelModules = ["kvm-intel"];
        disko = recursiveUpdate lvmDisko {
          devices.disk.base = {
            device = "/dev/disk/by-id/scsi-36b82a720cf60ce002a80577e12e4a1a7";
            content.partitions.root.end = "-1T";
          };
        };
      };
    };
    # systeamadeck = {
    #   install.host = "";
    #   target.sshOptions = sshOptions;
    #   profiles.system.module = {
    #     imports = [inputs.jovian.nixosModules.jovian];
    #     dotfiles.graphical.enable = true;
    #     # TODO do I need to extract mura correction images?
    #     # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/issues/227
    #     # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/pull/229
    #     jovian.decky-loader.enable = true;
    #     jovian.devices.steamdeck = {
    #       enable = true;
    #       autoUpdate = true;
    #       enableGyroDsuService = true;
    #     };
    #     jovian.steam = {
    #       enable = true;
    #       autoStart = true;
    #       desktopSession = "plasma";
    #       user = config.canivete.people.me;
    #     };
    #     networking.networkmanager.enable = true;

    #     # jovian.steam.autoStart conflicts
    #     services.displayManager.sddm.enable = false;
    #   };
    # };
  };
}
