{inputs, ...}: {
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) fileContents mkDefault mkForce mkIf mkMerge mkOption types;
    inherit (types) attrsOf enum submodule;
  in {
    options.nodes = mkOption {
      type = attrsOf (submodule ({config, ...}: {
        options.platform = mkOption {
          type = enum ["prem" "google" "hetzner"];
          default = "prem";
        };
        config = mkMerge [
          (mkIf (config.platform == "google") {
            system = {modulesPath, ...}: {
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
          (mkIf (config.platform == "hetzner") {
            system.imports = with inputs.srvos.nixosModules; [server hardware-hetzner-cloud];
          })
        ];
      }));
    };
    config = mkMerge [
      {
        nixos = {
          flake,
          pkgs,
          ...
        }: {
          canivete.kubernetes.enable = mkDefault true;
          environment.systemPackages = with pkgs; [ranger vim];
          networking.hostName = mkForce "";
          networking.firewall.allowedTCPPorts = [6443];
          users.users.root.openssh.authorizedKeys.keys = [(fileContents (inputs.self + "/${flake.config.canivete.sops.directory}/me.pub"))];
          # NOTE currently necessary for sops-install-secrets to exist instead of a system activation script
          # TODO should this go upstream? worth checking how stable this is and community commentary thereof
          services.userborn.enable = true;
          system.stateVersion = "25.05";

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
    ];
  };
}
