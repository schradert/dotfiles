{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete.people) me users;
in {
  canivete.deploy.nixos.modules.default = {
    config,
    lib,
    options,
    ...
  }: let
    inherit (lib) mapAttrsToList mkDefault mkForce mkMerge toList;
    mkUserModule = username: user: {
      home-manager.users.${username}.home = {inherit username;};
      systemd.services."home-manager-${username}".serviceConfig.TimeoutStartSec = mkForce "10m";
      users.groups.${username} = {};
      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        description = user.name;
        extraGroups = ["wheel" "tty" "networkmanager" username];
      };
    };
  in {
    imports = [inputs.disko.nixosModules.disko];
    config = mkMerge ((mapAttrsToList mkUserModule users) ++ toList {
      dotfiles.common = true;
      dotfiles.containers = true;
      dotfiles.programs.git.enable = true;
      dotfiles.programs.wordnet.enable = true;
      boot.initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      hardware.enableRedistributableFirmware = mkDefault true;
      hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
      hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
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
      time.timeZone = "America/Los_Angeles";
      users.mutableUsers = true;
    });
  };
}
