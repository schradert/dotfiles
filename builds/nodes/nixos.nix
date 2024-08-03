{
  config,
  inputs,
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
        powerManagement.cpuFreqGovernor = "powersave";
      };
    };
    sirver.profiles.system.module = {
      dotfiles.kubernetes.enable = true;
      boot.initrd.availableKernelModules = ["ehci_pci" "megaraid_sas" "usbhid"];
      home-manager.sharedModules = nix.toList {home.stateVersion = "23.05";};
    };
    systeamadeck.profiles.system.module = {
      imports = [inputs.jovian.nixosModules.jovian];
      dotfiles.graphical.enable = true;
      # TODO do I need to extract mura correction images?
      # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/issues/227
      # NOTE https://github.com/Jovian-Experiments/Jovian-NixOS/pull/229
      jovian.decky-loader.enable = true;
      jovian.devices.steamdeck = {
        enable = true;
        autoUpdate = true;
        enableGyroDsuService = true;
      };
      jovian.steam = {
        enable = true;
        autoStart = true;
        desktopSession = "plasma";
        user = config.people.me;
      };
      networking.networkmanager.enable = true;
    };
  };
}
