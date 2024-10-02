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
    boot.initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    hardware.enableRedistributableFirmware = mkDefault true;
    hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    home-manager.useGlobalPkgs = true;
    home-manager.sharedModules = toList {
      options.dotfiles = options.dotfiles;
      config.dotfiles = config.dotfiles;
      config.home.stateVersion = "24.05";
    };
    i18n.defaultLocale = "en_US.UTF-8";
    networking.useDHCP = mkDefault true;
    security.sudo.extraRules = toList {
      users = [me];
      commands = toList {
        command = "ALL";
        options = ["NOPASSWD"];
      };
    };
    services.earlyoom.enable = true;
    system.stateVersion = "24.05";
    systemd.services = flip mapAttrs' config.home-manager.users (username: _: nameValuePair "home-manager-${username}" {serviceConfig.TimeoutStartSec = mkForce "10m";});
    time.timeZone = "America/Los_Angeles";
    users.mutableUsers = true;
    users.groups = mapAttrs (username: _: {}) users;
    users.users = flip mapAttrs users (username: user: {
      isNormalUser = true;
      home = "/home/${username}";
      description = user.name;
      extraGroups = ["wheel" "tty" "networkmanager" username];
    });
  };
}
