{
  flake.nixosModules.hardware = {
    config,
    nix,
    ...
  }:
    with nix; {
      boot = {
        initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
        kernelModules = ["kvm-intel"];
        loader.efi.efiSysMountPoint = "/boot";
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/root";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };

      hardware.enableRedistributableFirmware = mkDefault true;
      hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
      networking.useDHCP = mkDefault true;
      swapDevices = [{device = "/dev/disk/by-label/swap";}];
    };
}
