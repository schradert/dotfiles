{
  config,
  nix,
  ...
}: let
  inherit (config.canivete) root;
in {
  canivete.deploy.nixos.nodes = {
    sirver = {
      install.host = "192.168.50.23";
      install.sshOptions = nix.mkForce [];
      target.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        dotfiles.kubernetes.root = true;
        dotfiles.devops.enable = true;
        disko.devices.disk.base.device = "/dev/disk/by-id/scsi-361866da05a3c260002ecf1a16170342b";
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
        boot.kernelModules = ["kvm-intel"];
        home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
        system.stateVersion = "24.05";
      };
    };
    axolotl = {
      install.host = "192.168.50.250";
      build.host = root;
      build.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.sshProtocol = "ssh";
      profiles.system.module = {
        dotfiles.graphical.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
        disko.devices.disk.base.device = "/dev/disk/by-id/nvme-SPCC_M.2_PCIE_SSD_30012119169";
        powerManagement.cpuFreqGovernor = "powersave";
        home-manager.sharedModules = nix.toList {
          dotfiles.macchina.networkInterface = "enp0s31f6";
          home.stateVersion = "24.05";
        };
        system.stateVersion = "24.05";
      };
    };
    bonobo = {
      install.host = "192.168.50.142";
      build.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko.devices.disk.base.device = "/dev/disk/by-id/ata-Micron_1100_SATA_256GB_165015496CBD";
        home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
        system.stateVersion = "24.05";
      };
    };
    chinchilla = {
      install.host = "192.168.50.85";
      build.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko.devices.disk.base.device = "/dev/disk/by-id/ata-MTFDDAK256TBN-1AR1ZABHA_UGXVK01J7BDCER";
        home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
        system.stateVersion = "24.05";
      };
    };
    dingo = {
      install.host = "192.168.50.105";
      build.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["xhci_pci" "usbhid"];
        disko.devices.disk.base.device = "/dev/disk/by-id/ata-LITEON_IT_LCS-256L9S_SD0E97900L2TH61100DL";
        home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
        system.stateVersion = "24.05";
      };
    };
    octopus = {
      install.host = "192.168.50.53";
      target.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
      profiles.system.module = {
        dotfiles.kubernetes.enable = true;
        boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid" "sr_mod"];
        boot.kernelModules = ["kvm-intel"];
        disko.devices.disk.base.device = "/dev/disk/by-id/scsi-36b82a720cf60ce002a80577e12e4a1a7";
        home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
        system.stateVersion = "24.05";
      };
    };
    # systeamadeck = {
    #   install.host = "";
    #   target.sshOptions = ["ProxyJump=${config.dotfiles.domain}"];
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
    #     home-manager.sharedModules = nix.toList {home.stateVersion = "24.05";};
    #     system.stateVersion = "24.05";

    #     # jovian.steam.autoStart conflicts
    #     services.displayManager.sddm.enable = false;
    #   };
    # };
  };
}
