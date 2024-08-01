{
  config,
  nix,
  ...
}: {
  canivete.deploy.nixos.nodes = {
    chilldom = {
      build.host = "sirver";
      build.sshFlags = "-J ${config.dotfiles.domain}";
      profiles.system.module = {
        dotfiles.graphical.enable = true;
        home-manager.sharedModules = nix.toList {
          dotfiles.macchina.networkInterface = "enp0s31f6";
          home.stateVersion = "23.05";
        };
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "rtsx_pci_sdmmc"];
        networking.hostName = "chilldom";
        powerManagement.cpuFreqGovernor = "powersave";
      };
    };
    sirver.profiles.system.module = {
      dotfiles.kubernetes.enable = true;
      boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
      home-manager.sharedModules = nix.toList {home.stateVersion = "23.05";};
      networking.hostName = "sirver";
    };
  };
}
