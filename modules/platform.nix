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
    config,
    lib,
    ...
  }: let
    inherit (config) me;
    inherit (lib) fileContents genList mkDefault mkForce mkIf mkMerge mkOption types;
    inherit (types) attrTag enum str submodule;
  in {
    options.nodes = canivete.mkNestedSubmodule ({
      config,
      name,
      ...
    }: let
      inherit (config) platform;
    in {
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
          mobile = mkOption {
            type = submodule {
              options.device = mkOption {
                type = str;
              };
            };
          };
          wsl = mkOption {
            type = submodule {};
          };
        };
      };
      config = mkMerge [
        {system._module.args = {inherit platform;};}
        (mkIf (platform ? prem) {
          system.boot.loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
          opentofu.module."nixos_${name}_system_install".target_host = mkForce platform.prem.install_host;
        })
        (mkIf (platform ? google) {
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
        (mkIf (platform ? hetzner) {
          system.imports = with inputs.srvos.nixosModules; [server hardware-hetzner-cloud];
          system.dotfiles.facter.reportName = "hetzner";
          opentofu.resource.hcloud_server.${name} = mkMerge [
            {
              depends_on = ["hcloud_ssh_key.me"];
              inherit name;
              inherit (platform.hetzner) server_type;
              location = "ash";
              image = "debian-12";
              keep_disk = true;
              ssh_keys = ["me"];

              lifecycle.ignore_changes = ["ssh_keys"];
            }
          ];
          opentofu.module."nixos_${name}_system_install".depends_on = ["hcloud_server.${name}"];
        })
        (mkIf (platform ? mobile) {
          system = {
            imports = [(import "${inputs.mobile-nixos}/lib/configuration.nix" {inherit (platform.mobile) device;})];
            # TODO why didn't this recent fix work https://github.com/mobile-nixos/mobile-nixos/issues/820
            disabledModules = [
              # NOTE avoiding module entirely for now
              "${inputs.mobile-nixos}/modules/system-target.nix"
              # TODO consider not defaulting to disko upstream
              "${inputs.disko}/module.nix"
            ];
            # Essential option in mobile-nixos
            options.mobile = {
              system.system = mkOption {
                # Known supported target types.
                type = enum [
                  "aarch64-linux"
                  "armv7l-linux"
                  "x86_64-linux"
                ];
                description = ''
                  Defines the host platform architecture the device is.

                  This will automagically setup cross-compilation where possible.
                '';
              };
            };
            config = {
              dotfiles.nixpkgs.config.allowUnfreePackages =
                {
                  oneplus-enchilada = ["oneplus-sdm845-firmware" "oneplus-sdm845-firmware-zstd"];
                }.${
                  platform.mobile.device
                } or [
                ];
              users.users.${me}.extraGroups = ["dialout" "feedbackd" "networkmanager"];
              # Ensures any rndis config from stage-1 is not clobbered by NetworkManager
              networking.networkmanager.unmanaged = ["rndis0" "usb0"];

              zramSwap.enable = mkDefault true;
              services.displayManager.autoLogin = {
                enable = mkDefault true;
                user = mkDefault me;
              };
              mobile = {
                boot.stage-1.networking.enable = mkDefault true;
                # Ensures all example systems float up normalization issues by default.
                boot.stage-1.kernel.useStrictKernelConfig = mkDefault true;
                beautification.silentBoot = mkDefault true;
                beautification.splash = mkDefault true;
              };

              dotfiles.profiles.client.enable = true;
              # TODO v4l2loopback build breaks with strange self.kernel.commonMakeFlags missing...
              dotfiles.programs.obs-studio.enable = mkForce false;
            };
          };
        })
        (mkIf (platform ? wsl) {
          system = {
            imports = [inputs.nixos-wsl.nixosModules.default];
            wsl.enable = true;
            wsl.defaultUser = me;
            wsl.startMenuLaunchers = true;
            # TODO figure out hardwired internet setup (switch + ethernet to usb adapters)
            # TODO should I I use wsl-vpnkit?
            # TODO value of OpenGL driver from Windows?
            # TODO any settings I should configure for more resource usage or enable graphical applications?
            # wsl.usbip.enable = true;
            # wsl.usbip.autoAttach = [];
            # wsl.usbip.snippetIpAddress = "127.0.0.1";
            # wsl.useWindowsDriver = true;
            # wsl.wslConf = {};
          };
        })
      ];
    });
  };
}
