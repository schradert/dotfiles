{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete) nodes;
  pubKey = inputs.self + "/${config.canivete.sops.directory}/${config.canivete.meta.people.me}.pub";
in {
  dotfiles = {
    canivete,
    lib,
    ...
  }: let
    inherit (lib) fileContents genList mkForce mkIf mkMerge mkOption types;
    inherit (types) attrTag enum str submodule;
  in {
    options.nodes = canivete.mkNestedSubmodule ({
      config,
      name,
      ...
    }: {
      options.platform = mkOption {
        default.prem = {};
        # TODO make this dynamic to activated clouds
        type = attrTag {
          prem = mkOption {
            type = submodule {
              options.install_host = mkOption {
                type = str;
                description = "Initial installation target";
              };
            };
          };
          google = mkOption {
            type = submodule {};
          };
          hetzner = mkOption {
            type = submodule {
              options.server_type = mkOption {
                type = enum (genList (i: "cpx${builtins.toString (i + 1)}1") 3);
              };
            };
          };
        };
      };
      config = mkMerge [
        (mkIf (config.platform ? prem) {
          system.boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
          opentofu.module."nixos_${name}_system_install".target_host = mkForce config.platform.prem.install_host;
        })
        (mkIf (config.platform ? google) {
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
            networking.extraHosts = "169.254.169.254 metadata.google.internal metadata";

            # Delegate to gcloud firewall
            networking.firewall.enable = mkForce false;
          };
          opentofu.resource.google_compute_instance.${name} = mkMerge [
            {
              # TODO what scopes will I need to set?
              inherit name;
              machine_type = "e2-standard-4";
              allow_stopping_for_update = true;
              boot_disk.initialize_params = {
                type = "pd-balanced";
                size = 200;
                image = "debian-12";
              };
              metadata_startup_script = "sed -i 's/PermitRootLogin no/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config";
              metadata.ssh-keys = "root:${fileContents pubKey} root";
              service_account.email = "\${ google_service_account.compute.email }";
              service_account.scopes = ["cloud-platform"];

              inherit (nodes.${name}) hostname;
              network_interface.subnetwork = "\${ google_compute_subnetwork.main.name }";
              can_ip_forward = true;
            }
          ];
          opentofu.module."nixos_${name}_system_install".depends_on = ["google_compute_instance.${name}"];
        })
        (mkIf (config.platform ? hetzner) {
          system.imports = with inputs.srvos.nixosModules; [server hardware-hetzner-cloud];
          system.dotfiles.facter.reportName = "hetzner";
          opentofu.resource.hcloud_server.${name} = mkMerge [
            {
              depends_on = ["hcloud_ssh_key.me"];
              inherit name;
              inherit (config.platform.hetzner) server_type;
              location = "ash";
              image = "debian-12";
              keep_disk = true;
              ssh_keys = ["me"];

              lifecycle.ignore_changes = ["ssh_keys"];
            }
          ];
          opentofu.module."nixos_${name}_system_install".depends_on = ["hcloud_server.${name}"];
        })
      ];
    });
  };
}
