flake @ {
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (canivete) mkModuleOption;
  inherit (config.dotfiles) domain me nodes people root nixos darwin droid home-manager opentofu kubenix shared system;
  inherit (lib) mapAttrs mkEnableOption mkForce mkIf mkOption mkMerge types;
  inherit (types) attrsOf str submodule;
  keyFile = "/root/.config/sops/age/keys.txt";
in {
  options.dotfiles = mkOption {
    default = {};
    description = "Project infrastructure";
    type = submodule ({config, ...}: {
      options = {
        domain = mkOption {
          type = str;
          description = "Production deployment domain";
        };
        root = mkOption {
          type = str;
          description = "Production root server";
        };
        me = mkOption {
          type = str;
          description = "Production primary admin";
        };
        people = mkOption {
          type = attrsOf str;
          default = {};
          description = "Shorthand to email username";
        };
        nodes = mkOption {
          type = attrsOf (submodule {
            options.system = mkModuleOption {description = "Node system profile";};
            options.opentofu = mkModuleOption {description = "Node opentofu";};
          });
          default = {};
          description = "Nodes the cluster runs on";
        };
        nixos = mkModuleOption {description = "Common NixOS configuration for nodes";};
        shared = mkModuleOption {description = "Common profile configuration for nodes";};
        system = mkModuleOption {description = "Common system configuration for nodes";};
        darwin = mkModuleOption {description = "Common nix-darwin configuration for nodes";};
        droid = mkModuleOption {description = "Common nix-on-droid configuration for nodes";};
        home-manager = mkModuleOption {description = "Common home-manager configuration for nodes";};
        opentofu = mkModuleOption {description = "Common OpenTofu configuration";};
        kubenix = mkModuleOption {description = "Common kubenix configuration";};
        clouds = {
          hetzner.enable = mkEnableOption "Hetzner Cloud";
          google.enable = mkEnableOption "Google Cloud";
        };
      };
      config = {
        _module.args = {inherit canivete;};
        nixos = {
          config,
          pkgs,
          ...
        }: {
          _module.args = {inherit (inputs.nix2container.packages.${pkgs.system}) nix2container;};
          canivete.kubernetes.images.airgap = config.services.k3s.package.airgapImages;
          sops.age.keyFile = mkForce keyFile;
        };
        opentofu = mkMerge [
          {
            kubernetes.cluster = "deploy";
            modules.module."nixos_${root}_system_install".flake = mkForce ".#bootstrap";
          }
          (mkIf config.clouds.hetzner.enable {
            plugins = ["hetznercloud/hcloud"];
            modules.provider.hcloud.token = canivete.vals.sops.default "hetzner/token";
            modules.resource.hcloud_ssh_key.me = {
              name = "me";
              public_key = "\${ file(\"\${local.SOPS_DIR}/me.pub\") }";
            };
          })
        ];
        kubenix = {pkgs, ...}: {
          # NOTE nothing currently defined upstream and I don't know what features I'm even using
          options.kubernetes.api.resources."kapp.k14s.io".v1alpha1.Config = mkOption {
            type = attrsOf (submodule {freeformType = (pkgs.formats.yaml {}).type;});
          };
          config.kubernetes.resources.namespaces = {
            # TODO define all namespaces (dynamically?!)
            cicd = {};
            monitoring = {};
            security = {};
            storage = {};
          };
        };
      };
    });
  };
  config = {
    # Deploy root first without tailscale + cilium to avoid infinite recursion/lockout
    flake.nixosConfigurations.bootstrap = config.flake.nixosConfigurations.${root}.extendModules {
      modules = [
        {
          canivete.kubernetes.enable = false;
          dotfiles.cilium.enable = false;
          dotfiles.tailscale.enable = false;
        }
      ];
    };
    canivete.deploy = {
      sshUser = "root";
      # TODO why does this fail with "-oPermitLocalCommand: not found"?
      # sshOpts = ["StrictHostKeyChecking=accept-new"];
      canivete.modules = {inherit droid nixos darwin home-manager shared system;};
      nodes =
        mapAttrs (name: modules: {
          # TODO prevent hardcoding this subdomain
          hostname = "${name}.vpn.${domain}";
          profiles.system.canivete = {
            configuration = modules.system;
            opentofu = {pkgs, ...}: {
              imports = [modules.opentofu];
              # TODO is there a better way to add these things?!
              module."nixos_${name}_system_install" = {
                depends_on = mkIf (name != root) ["shell_script.headscale_pre_auth_key-main"];
                extra_environment.SOPS_BIN = "\${ local.SOPS_BIN }";
                extra_environment.SOPS_DIR = "\${ local.SOPS_DIR }";
                extra_files_script = toString (pkgs.writeShellScript "extra-files-script" ''
                  key_f="$(pwd)${keyFile}"
                  mkdir -p "$(dirname "$key_f")"
                  pushd ${inputs.self}
                  $SOPS_BIN --decrypt "$SOPS_DIR/me.txt" >"$key_f"
                  popd
                  chmod 400 "$key_f"
                '');
              };
            };
          };
        })
        nodes;
    };
    canivete.meta = {
      inherit domain root;
      people = {
        inherit me;
        users =
          mapAttrs (_: username: {
            name = username;
            profiles.default.email = "${username}@${domain}";
          })
          people;
      };
    };
    perSystem = {
      config,
      pkgs,
      ...
    }: {
      # TODO put this into a module
      canivete.devShells.shells.default = {
        packages = [pkgs.hcloud];
        shellHook = "export HCLOUD_TOKEN=$(${lib.getExe config.canivete.sops.package} --decrypt --extract '[\"hetzner\"][\"token\"]' \"${flake.config.canivete.sops.default}\")";
      };
      canivete.kubenix.clusters.deploy = kubenix;
      canivete.opentofu.workspaces.deploy = {...}: {imports = [opentofu];};
    };
  };
}
