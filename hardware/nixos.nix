{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete.meta.people) users;
in {
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) fileContents mapAttrsToList mkDefault mkForce mkIf mkMerge;
    mkUserModule = username: user: {
      home-manager.users.${username}.home = {inherit username;};
      systemd.services."home-manager-${username}".serviceConfig.TimeoutStartSec = mkForce "10m";
      users.groups.${username} = {};
      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        description = user.name;
        extraGroups = ["wheel" "tty" "networkmanager" "audio" "video" username];
      };
    };
  in {
    config = mkMerge [
      {
        nixos = {
          config,
          flake,
          options,
          pkgs,
          ...
        }: {
          imports = [inputs.nur.modules.nixos.default] ++ (mapAttrsToList mkUserModule users);
          boot.initrd.availableKernelModules = ["ahci" "usb_storage" "sd_mod"];
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          hardware.enableRedistributableFirmware = mkDefault true;
          hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
          hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
          canivete.kubernetes.enable = mkDefault true;
          dotfiles.containers = true;
          environment.systemPackages = with pkgs; [ranger vim];
          i18n.defaultLocale = "en_US.UTF-8";
          location.latitude = 37.8;
          location.longitude = -122.4;
          networking.hostName = mkForce "";
          networking.firewall.allowedTCPPorts = [6443];
          networking.useDHCP = mkDefault true;
          services.cloud-init.enable = false;
          services.earlyoom.enable = true;
          # NOTE currently necessary for sops-install-secrets to exist instead of a system activation script
          # TODO should this go upstream? worth checking how stable this is and community commentary thereof
          services.userborn.enable = true;
          # FIXME should I reset everything
          # system.stateVersion = mkDefault "24.05";
          system.stateVersion = "25.05";
          time.timeZone = "America/Los_Angeles";
          users.users.root.openssh.authorizedKeys.keys = [(fileContents (inputs.self + "/${flake.config.canivete.sops.directory}/me.pub"))];

          home-manager.backupFileExtension = "bak";
          home-manager.useGlobalPkgs = true;
          home-manager.sharedModules = [
            {
              options.dotfiles = options.dotfiles;
              config.dotfiles = config.dotfiles;
              config.home.stateVersion = "24.05";
            }
            {
              dotfiles.common = true;
              dotfiles.programs.git.enable = true;
            }
          ];
          disko.devices.disk.base = {
            device = "/dev/sda";
            type = "disk";
            content.type = "gpt";
            content.partitions = {
              # TODO does this work on GCE?
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
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  # TODO just on GCE? how does this relate to boot.growPartition?
                  # Root partition must be resizable
                  mountOptions = ["defaults" "x-systemd.growfs"];
                };
              };
            };
          };
        };
      }
      (mkIf config.platforms.google.enable {
        nixos = {modulesPath, ...}: {
          # FIXME why is it failing with these upstream modules?
          imports = [
            "${toString modulesPath}/profiles/headless.nix"
            "${toString modulesPath}/profiles/qemu-guest.nix"
            # inputs.srvos.nixosModules.server
            # inputs.nixos-generators.nixosModules.gce
          ];
          # virtualisation.googleComputeImage.efi = true;

          # Recreated essentials from nixos-generators
          services.openssh.enable = true;
          boot.initrd.availableKernelModules = ["nvme"];
          boot.initrd.kernelModules = ["virtio_scsi"];
          boot.kernelParams = ["console=ttyS0"];
          boot.kernelModules = ["virtio_pci" "virtio_net"];
          boot.loader.systemd-boot.enable = true;
          networking.extraHosts = "169.254.169.254 metadata.google.internal metadata";

          # Delegate to gcloud firewall
          networking.firewall.enable = mkForce false;
        };
      })
      (mkIf config.platforms.hetzner.enable {
        nixos.imports = with inputs.srvos.nixosModules; [server hardware-hetzner-cloud];
      })
    ];
  };
}
