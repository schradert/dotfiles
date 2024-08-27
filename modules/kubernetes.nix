{
  config,
  nix,
  ...
}:
with nix; let
  inherit (config.dotfiles) domain;
  # TODO how can I bootstrap images onto the server to allow every other deployment to use this?
in {
  perSystem = {
    config,
    inputs',
    pkgs,
    self',
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
            # TODO bootstrap
            # default = "harbor.${domain}";
            default = "docker.io";
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
    options.dotfiles.helm = mkOption {
      default = {};
      type = attrsOf (submodule {
        freeformType = anything;
        options = {
          chart = mkOption {
            type = attrsOf anything;
            default = {};
          };
          values = mkOption {
            inherit (pkgs.formats.yaml {}) type;
            default = {};
          };
          resources = mkOption {
            inherit (pkgs.formats.yaml {}) type;
            default = {};
          };
        };
      });
    };
    config.canivete.opentofu.workspaces.deploy.modules = {
      k3s-token.resource.random_password.k3s-token.length = 21;
      nix2container = {
        config = mkMerge (flip mapAttrsToList config.dotfiles.nix2container (name: container: let
          path = "dotfiles.x86_64-linux.nix2container.${name}.image";
        in {
          resource.null_resource.kubernetes = {
            # TODO bootstrap
            # depends_on = ["null_resource.${name}"];
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
          # TODO bootstrap
          # resource.null_resource.${name} = {
          #   triggers.drv = "\${ data.external.${name}.result.drv }";
          #   provisioner.local-exec.command = "nix run .#${path}.copyToRegistry";
          # };
        }));
      };
    config.canivete.kubenix.clusters = let
      mapReleases = releases: helm: mkMerge (flip mapAttrsToList releases (name: cfg: {
        kubernetes = {
          resources = mkMerge [
            cfg.resources
            # TODO fix this with resources.imports
            (flip mapAttrs cfg.resources (_: type:
              flip mapAttrs type (_: _: {
                metadata.namespace = mkDefault cfg.namespace;
                metadata.labels."canivete/chart" = mkDefault name;
              })))
          ];
          helm.releases.${name} = mkMerge [
            (removeAttrs cfg ["chart" "resources" "bootstrap"])
            {
              chart = pipe cfg.chart [
                # Good template chart to make deployment easier and more powerful
                (mergeAttrs {
                  repo = "https://bjw-s.github.io/helm-charts";
                  chart = "app-template";
                  version = "3.3.2";
                  sha256 = "9Lx3jPGiLaE+joGy2GWxLzjWDu8wCa+4DrS9atf2zug=";
                })
                helm.fetch
              ];
            }
          ];
        };
      }));
      fetchKubeconfig = "ssh ${root} sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${domain}/'";
      prod.modules.helm = {helm, ...}: {config = mapReleases config.dotfiles.helm helm;};
      prod.deploy.fetchKubeconfig = fetchKubeconfig;
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
