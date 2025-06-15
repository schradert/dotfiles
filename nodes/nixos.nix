{
  config,
  inputs,
  ...
}: let
  inherit (config.canivete) nodes;
  pubKey = inputs.self + "/${config.canivete.sops.directory}/me.pub";
in {
  perSystem.canivete.pre-commit.settings.excludes = ["nodes/nodes/.+\\.json"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) root;
    inherit (lib) fileContents genList mkDefault mkForce mkIf mkMerge mkOption types;
    inherit (types) attrsOf attrTag enum submodule;
  in {
    options.nodes = mkOption {
      type = attrsOf (submodule ({
        config,
        name,
        ...
      }: {
        options.platform = mkOption {
          default.prem = {};
          # TODO make this dynamic to activated clouds
          type = attrTag {
            prem = mkOption {
              type = submodule {};
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
            opentofu.modules.resource.google_compute_instance.${name} = mkMerge [
              (mkIf (name == root) {network_interface.access_config.nat_ip = "\${ local.root_ip }";})
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
            opentofu.modules.module."nixos_${name}_system_install".depends_on = ["google_compute_instance.${name}"];
          })
          (mkIf (config.platform ? hetzner) {
            system.imports = with inputs.srvos.nixosModules; [server hardware-hetzner-cloud];
            opentofu.modules.resource.hcloud_server.${name} = mkMerge [
              (mkIf (name == root) {public_net.ipv4 = "\${ local.root_ip }";})
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
            opentofu.modules.module."nixos_${name}_system_install".depends_on = ["hcloud_server.${name}"];
          })
        ];
      }));
    };
    config = mkMerge [
      {
        nixos = {pkgs, ...}: {
          imports = [inputs.nur.modules.nixos.default];
          boot.loader.systemd-boot.enable = true;
          environment.systemPackages = with pkgs; [ranger vim];
          i18n.defaultLocale = "en_US.UTF-8";
          networking.hostName = mkForce "";
          services.earlyoom.enable = true;
          # NOTE currently necessary for sops-install-secrets to exist instead of a system activation script
          # TODO should this go upstream? worth checking how stable this is and community commentary thereof
          services.userborn.enable = true;
          system.stateVersion = "25.05";
          users.users.root.openssh.authorizedKeys.keys = [(fileContents pubKey)];
        };
        shared = {lib, ...}: {
          options.dotfiles.profiles.client.enable = lib.mkEnableOption "client configuration";
        };
      }
      {
        nixos = {
          config,
          flake,
          lib,
          options,
          ...
        }: {
          config = lib.mkIf config.dotfiles.profiles.client.enable (lib.mkMerge [
            (lib.flip lib.mapAttrsToList flake.config.canivete.meta.people.users (username: user: {
              home-manager.users.${username}.home = {inherit username;};
              # Can be quite large...
              systemd.services."home-manager-${username}".serviceConfig.TimeoutStartSec = mkForce "10m";
              users.groups.${username} = {};
              users.users.${username} = {
                isNormalUser = true;
                home = "/home/${username}";
                description = user.name;
                extraGroups = ["wheel" "tty" "networkmanager" "audio" "video" username];
              };
            }))
            {
              home-manager.backupFileExtension = "bak";
              home-manager.useGlobalPkgs = true;
              home-manager.sharedModules = [
                {
                  options.dotfiles = options.dotfiles;
                  config.dotfiles = config.dotfiles;
                  config.home.stateVersion = "25.05";
                }
              ];
            }
          ]);
        };
      }
      {
        system = {lib, ...}: {
          options.dotfiles.profiles.server.enable = lib.mkEnableOption "server configuration";
        };
        nixos = {
          config,
          lib,
          ...
        }: {
          config = lib.mkIf config.dotfiles.profiles.server.enable {
            canivete.kubernetes.enable = true;
            networking.firewall.allowedTCPPorts = [6443];
          };
        };
      }
    ];
  };
}
