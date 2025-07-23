{
  canivete,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (builtins) concatStringsSep elem filter map match readFile toString;
  inherit (lib) filterAttrs flatten flip hasSuffix mapAttrsToList mkDefault mkEnableOption mkIf mkMerge mkOption pipe toList types;
  inherit (types) attrsOf listOf package str submodule;
  mkTypeOption = type: canivete.mkOverrideOption {inherit type;};
  getGVKN = o: concatStringsSep "/" [o.apiVersion o.kind o.metadata.name];
in {
  perSystem = {
    inputs',
    pkgs,
    system,
    ...
  }: {
    canivete.pre-commit.settings = {
      excludes = ["generated"];
      hooks.lychee.toml.exclude = ["https://192.168.50.*"];
    };
    legacyPackages.nixidyEnvs.${system} = inputs.nixidy.lib.mkEnvs {
      inherit pkgs;
      modules = [config.dotfiles.nixidy];
      charts = inputs.nixhelm.chartsDerivations.${system};
      extraSpecialArgs = {inherit inputs';};
      envs.prod = {};
    };
  };
  dotfiles = _: {
    options.nixidy = canivete.mkModuleOption {description = "Common nixidy configuration";};
    config = {
      nixos = {
        config,
        pkgs,
        ...
      }: {
        config = mkMerge [
          {
            _module.args = {inherit (inputs.nix2container.packages.${pkgs.system}) nix2container;};
            canivete.kubernetes.images.airgap = config.services.k3s.package.airgapImages;
          }
          (mkIf config.dotfiles.profiles.server.enable {
            networking.firewall.allowedTCPPorts = [6443];
            systemd.services.k3s.serviceConfig.TimeoutStartSec = 600;
          })
        ];
      };
      opentofu.modules = {perSystem, ...}: {
        resource.null_resource.kubernetes = {
          # TODO avoid hardcoding root and env names
          depends_on = ["module.nixos_sirver_system_install"];
          provisioner.local-exec.command = "nix run \${ var.GIT_DIR }#nixidyEnvs.${perSystem.system}.prod.config.build.scripts.bootstrap";
        };
      };
      nixidy = {
        config,
        lib,
        ...
      }: {
        imports = [
          # CRDs
          ({
            config,
            inputs',
            ...
          }: {
            options.dotfiles.crds = mkOption {
              default = {};
              type = attrsOf (submodule ({
                config,
                name,
                ...
              }: {
                options = {
                  src = mkTypeOption package {};
                  name = mkTypeOption str {default = name;};
                  namePrefix = mkTypeOption str {default = "";};
                  attrNameOverrides = mkTypeOption (attrsOf str) {default = {};};
                  crds = mkTypeOption (listOf str) {internal = true;};

                  install = mkEnableOption "install CRDs";
                  application = mkTypeOption str {default = name;};
                  prefix = mkTypeOption str {default = "";};
                  match = mkTypeOption str {default = ".+";};
                };
                config.crds = canivete.filesets.everything (name: _: hasSuffix ".yaml" name && match config.match name != null) (config.src + "/" + config.prefix);
              }));
            };
            config.applications = pipe config.dotfiles.crds [
              (filterAttrs (_: crd: crd.install))
              (mapAttrsToList (_: crd: {${crd.application}.yamls = map readFile crd.crds;}))
              mkMerge
            ];
            config.nixidy.applicationImports = flip mapAttrsToList config.dotfiles.crds (_: crd:
              toString (inputs'.nixidy.packages.generators.fromCRD {
                inherit (crd) name src namePrefix crds attrNameOverrides;
              }));
          })
          # Namespaces
          ({config, ...}: {
            nixidy.appOfApps.namespace = "cicd";
            nixidy.applicationImports = [
              (_: {
                defaults = toList {
                  kind = "Namespace";
                  default.metadata.annotations."argocd.argoproj.io/sync-options" = mkDefault "Prune=confirm";
                };
              })
            ];
            applications.${config.nixidy.appOfApps.name} = {
              defaults = toList {
                kind = "Namespace";
                default.metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false";
              };
              resources.namespaces = {
                cicd = {};
                monitoring = {};
                network = {};
                security = {};
                storage = {};
              };
            };
          })
          # Synchronization
          {
            nixidy.applicationImports = [
              (_: {
                syncPolicy.syncOptions = {
                  applyOutOfSyncOnly = true;
                  pruneLast = true;
                  serverSideApply = true;
                  failOnSharedResource = true;
                };
              })
            ];
            nixidy.defaults.syncPolicy.autoSync = {
              enable = true;
              prune = true;
              selfHeal = true;
            };
          }
          # Bootstrap
          ({
            config,
            pkgs,
            ...
          }: {
            options.build.scripts.bootstrap = mkOption {
              type = package;
              internal = true;
              description = "Command to bootstrap cluster";
            };
            config.nixidy.applicationImports = [
              (_: {
                options.dotfiles.bootstrap = {
                  enable = mkEnableOption "importing resources into cluster bootstrap";
                  exclude = mkTypeOption (listOf str) {default = [];};
                };
              })
            ];
            config.applications.__bootstrap.objects = pipe config.nixidy.publicApps [
              (filter (name: name != config.nixidy.appOfApps.name))
              (map (name: config.applications.${name}))
              (filter (app: app.dotfiles.bootstrap.enable))
              (map (app: filter (obj: !(elem (getGVKN obj) app.dotfiles.bootstrap.exclude)) app.objects))
              flatten
            ];
            config.build.scripts.bootstrap = pkgs.mkShellApplication {
              # Vals needs to run in the project root to read SOPS
              name = "nixidy-bootstrap-${config.nixidy.env}";
              runtimeInputs = [
                pkgs.git
                config.build.scripts.nixidy
                pkgs.vals
                config.build.scripts.kubeconfig
                pkgs.kapp
              ];
              text = ''
                cd "$(git rev-parse --show-toplevel)"
                nixidy bootstrap .#${config.nixidy.env} | \
                  vals eval -s -decode-kubernetes-secrets -f - | \
                  kubeconfig kapp deploy --yes --diff-changes --app bootstrap --file -
              '';
            };
          })
          # Kubeconfig
          ({pkgs, ...}: {
            options.build.scripts.kubeconfig = mkOption {
              type = package;
              internal = true;
              description = "Command to connect cluster";
            };
            config.build.scripts.kubeconfig = pkgs.mkShellApplication {
              name = "kubeconfig";
              runtimeInputs = with pkgs; [openssh tinybox];
              # TODO fix these hardcoded values
              text = ''
                KUBECONFIG="$(mktemp)"
                export KUBECONFIG
                trap 'rm -f "$KUBECONFIG"' EXIT
                ssh 192.168.50.58 sudo k3s kubectl config view --raw | \
                  sed 's/127\.0\.0\.1/192.168.50.58/' \
                  >"$KUBECONFIG"
                "''${@}"
              '';
            };
          })
          # Nixidy
          ({inputs', ...}: {
            options.build.scripts.nixidy = mkOption {
              type = package;
              internal = true;
              description = "Nixidy executable";
            };
            config.build.scripts.nixidy = inputs'.nixidy.packages.default;
          })
        ];
        nixidy.target.rootPath = "./generated/nixidy/${config.nixidy.env}";
        nixidy.defaults.helm.transformer = map (lib.kube.removeLabels [
          # Helm chart versions are just not necessary
          "app.kubernetes.io/version"
          "helm.sh/chart"
        ]);
      };
    };
  };
}
