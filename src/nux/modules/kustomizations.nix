{ config, lib, pkgs, ... }:
let cfg = config;
in {
  options.kustomizations = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({name, config, ...}: {
      options = {
        apiVersion = lib.mkOption {
          type = lib.types.str;
          default = "kustomize.toolkit.fluxcd.io/v1";
          example = "kustomize.toolkit.fluxcd.io/v1beta1";
          description = lib.mdDoc "Kubernetes apiVersion for resource";
        };
        kind = lib.mkOption {
          type = lib.types.str;
          default = "Kustomization";
          example = "MyKustomization";
          description = lib.mdDoc "Kubernetes resource type available at apiVersion";
        };
        metadata.name = lib.mkOption {
          type = lib.types.str;
          default = name;
          example = "my-kustomization";
          description = lib.mdDoc "The name of the resource";
        };
        metadata.namespace = lib.mkOption {
          type = lib.types.enum cfg.namespaces.all;
          default = "flux-system";
          example = "my-namespace";
          description = lib.mdDoc "The namespace for this resource";
        };
        spec = {
          interval = lib.mkOption {
            type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
            default = "1m0s";
            example = "23h59m59s";
            description = lib.mdDoc "Interval for syncing with repository";
          };
          timeout = lib.mkOption {
            type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
            default = "1m0s";
            example = "23h59m59s";
            description = lib.mdDoc "Interval to wait for repository sync to be successful";
          };
          retryInterval = lib.mkOption {
            type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
            default = "1m0s";
            example = "23h59m59s";
            description = lib.mdDoc "Interval for retrying to sync with repository";
          };
          wait = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = lib.mdDoc "Whether to wait for the resource to be deployed";
          };
          prune = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = lib.mdDoc "Whether to remove all resources when upstream source has changed";
          };
          targetNamespace = lib.mkOption {
            type = lib.types.enum cfg.namespaces.all;
            default = config.metadata.namespace;
            example = "my-namespace";
            description = lib.mdDoc "The namespace for the resources in this deployment";
          };
          path = lib.mkOption {
            type = lib.types.strMatching "\./.+";
            default = "./kustomize";
            example = "./path/to/kustomize/dir";
            description = lib.mdDoc "Where the kustomization files are for this deployment in source";
          };
          sourceRef.kind = lib.mkOption {
            type = lib.types.str;
            default = "GitRepository";
            example = "MyGitRepository";
            description = lib.mdDoc "Type of source repository";
          };
          sourceRef.name = lib.mkOption {
            type = lib.types.str;
            default = config.metadata.name;
            example = "my-git-repository";
            description = lib.mdDoc "Name of source repository in same Kustomization namespace";
          };
          patches = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                patch = lib.mkOption {
                  type = lib.types.str;
                  example = ''
                    apiVersion: autoscaling/v2
                    kind: HorizontalPodAutoscaler
                    metadata:
                      name: podinfo
                    spec:
                      minReplicas: 3
                  '';
                  description = lib.mdDoc "String YAML extra configuration";
                };
                target.name = lib.mkOption {
                  type = lib.types.str;
                  example = "my-deployment";
                  description = lib.mdDoc "The resource to direct this patch towards";
                };
                target.kind = lib.mkOption {
                  type = lib.types.str;
                  example = "MyHorizontalPodAutoscaler";
                  description = lib.mdDoc "The kind of resource to patch";
                };
              };
            });
            default = [];
            description = lib.mdDoc "Flux level overrides of deployment configuration";
          };
        };
      };
    }));
    default = {};
    description = lib.mdDoc "FluxCD HelmRelease resources";
  };
  config = let
    releases = builtins.attrValues cfg.releases.helm;
    releasesNames = builtins.attrNames cfg.releases.helm;
  in {
    resources = releases;
    assertions = lib.trivial.pipe releases [
      (map (lib.attrsets.attrByPath ["spec" "dependsOn"] null))
      (map (releaseName: {
        assertion = builtins.isNull releaseName || builtins.elem releaseName releasesNames;
        message = "'${releaseName}' is not an existing helm release to depend on";
      }))
    ];
  };
}
