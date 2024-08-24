{
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) me users;
in {
  # TODO investigate [ ] [sysdig](https://github.com/draios/sysdig)
  canivete.deploy.nixos.modules.default = {
    config,
    options,
    ...
  }: {
    imports = [inputs.disko.nixosModules.disko];
    disko.devices.disk.base = {
      device = mkDefault "/dev/sda";
      type = "disk";
      content.type = "gpt";
      content.partitions = {
        ESP = {
          type = "EF00";
          size = "500M";
          content.type = "filesystem";
          content.format = "vfat";
          content.mountpoint = "/boot";
        };
        root = {
          end = "-1G";
          content.type = "filesystem";
          content.format = "ext4";
          content.mountpoint = "/";
        };
        swap = {
          size = "100%";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
      };
    };
    boot = {
      initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
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
