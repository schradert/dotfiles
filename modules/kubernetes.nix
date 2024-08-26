{
  config,
  nix,
  ...
}:
with nix; let
  inherit (config.dotfiles) domain;
in {
  perSystem = {
    config,
    inputs',
    pkgs,
    self',
    system,
    ...
  }: {
    options.dotfiles.nix2container = mkOption {
      default = {};
      type = attrsOf (submodule ({
        name,
        config,
        ...
      }: {
        options = {
          registry = mkOption {
            type = str;
            default = "harbor.${domain}";
          };
          repository = mkOption {
            type = str;
            default = name;
          };
          package = mkOption {
            type = package;
            default = self'.packages.${name} or pkgs.${name};
          };
          tag = mkOption {
            type = str;
            default = config.package.version;
          };
          args = mkOption {
            type = attrsOf anything;
            default = {};
          };
          image = mkOption {
            type = package;
            default = pipe config.args [
              (recursiveUpdate {
                name = "${config.registry}/${config.repository}";
                inherit (config) tag;
                config.entrypoint = ["${config.package}/bin/${config.package.meta.mainProgram or name}"];
              })
              inputs'.nix2container.packages.nix2container.buildImage
            ];
          };
        };
      }));
    };
    config.canivete.opentofu.workspaces.deploy.modules = {
      k3s-token.resource.random_password.k3s-token.length = 21;
      nix2container = {
        config = mkMerge (flip mapAttrsToList config.dotfiles.nix2container (name: container: let
          path = "dotfiles.x86_64-linux.nix2container.${name}.image";
        in {
          resource.null_resource.kubernetes = {
            depends_on = ["null_resource.${name}"];
            provisioner.local-exec.environment = pipe ["tag" "registry" "repository" "fullRepository"] [
              (flip genAttrs (attr: "\${ data.external.${name}.result.${attr} }"))
              (mapAttrNames (key: "${toUpper name}_IMAGE_${toUpper key}"))
            ];
          };
          data.external.${name}.program = pkgs.execBash ''
            export \
              drv=$(nix path-info --derivation .#${path}) \
              tag=${container.tag} \
              registry=${container.registry} \
              repository=${container.repository} \
              fullRepository=${container.registry}/${container.repository}
            ${getExe pkgs.jq} --null-input '$ARGS.positional | map({(.):env[.]}) | add' --args drv tag registry repository fullRepository
          '';
          resource.null_resource.${name} = {
            triggers.drv = "\${ data.external.${name}.result.drv }";
            provisioner.local-exec.command = "nix run .#${path}.copyToRegistry";
          };
        }));
      };
    };
  };
  canivete.deploy.nixos.modules.kubernetes = {
    config,
    pkgs,
    perSystem,
    ...
  }: let
    cfg = config.dotfiles.kubernetes;
    cfg_k3s = config.services.k3s;
  in {
    options.dotfiles.kubernetes = {
      enable = mkEnableOption "kubernetes as a service";
      root = mkEnableOption "node as kubernetes main control plane";
    };
    config = mkIf cfg.enable {
      canivete.secrets."random_password.k3s-token" = "result";
      environment.systemPackages = [pkgs.k3s];
      networking.firewall.allowedTCPPorts = [6443];
      networking.firewall.allowedUDPPorts = [8472];
      services.k3s = mkMerge [
        {
          enable = true;
          tokenFile = "/private/canivete/secrets/random_password.k3s-token";
          role = mkDefault "agent";
          gracefulNodeShutdown.enable = true;
        }
        (mkIfElse cfg.root {
            clusterInit = true;
            role = "server";
          } {
            serverAddr = "https://${domain}:6443";
          })
        (mkIf (cfg_k3s.role == "server") {
          configPath = pkgs.writers.writeYAML "k3s.yaml" {
            disable = ["traefik"];
            disable-helm-controller = true;
            tls-san = [domain];
          };
        })
        (mkIf (cfg_k3s.disableAgent -> cfg_k3s.role == "agent") {
          images = mapAttrsToList (_: getAttr "image") perSystem.config.dotfiles.nix2container;
        })
      ];
    };
  };
}
