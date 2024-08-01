{
  config,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
in {
  canivete.deploy.nixos.modules.default = {
    config,
    options,
    ...
  }: {
    boot = {
      initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
      kernelModules = ["kvm-intel"];
      loader.efi.efiSysMountPoint = "/boot";
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    hardware.enableRedistributableFirmware = mkDefault true;
    hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    home-manager.useGlobalPkgs = true;
    home-manager.sharedModules = toList {
      options.dotfiles = options.dotfiles;
      config.dotfiles = config.dotfiles;
    };
    # TODO extract
    i18n.defaultLocale = "en_US.UTF-8";
    networking.useDHCP = mkDefault true;
    security.sudo.extraRules = toList {
      users = [me];
      commands = toList {
        command = "ALL";
        options = ["NOPASSWD"];
      };
    };
    swapDevices = [{device = "/dev/disk/by-label/swap";}];
    system.stateVersion = "22.11";
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = "github:schradert/dotfiles";
      persistent = true;
      rebootWindow.lower = "05:00";
      rebootWindow.upper = "06:00";
    };
    systemd.services = flip mapAttrs' config.home-manager.users (username: _: nameValuePair "home-manager-${username}" {serviceConfig.TimeoutStartSec = mkForce "10m";});
    time.timeZone = "America/Los_Angeles";
    users.mutableUsers = true;
    users.users = flip mapAttrs users (username: user: {
      isNormalUser = true;
      home = "/home/${username}";
      description = user.name;
      extraGroups = ["wheel" "tty" "networkmanager"];
    });
  };
}
