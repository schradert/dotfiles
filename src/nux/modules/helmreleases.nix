{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config;
in {
  options.releases.helm = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options = {
        apiVersion = lib.mkOption {
          type = lib.types.str;
          default = "helm.toolkit.fluxcd.io/v2beta1";
          example = "helm.toolkit.fluxcd.io/v1";
          description = lib.mdDoc "Kubernetes apiVersion for resource";
        };
        kind = lib.mkOption {
          type = lib.types.str;
          default = "HelmRelease";
          example = "MyHelmRelease";
          description = lib.mdDoc "Kubernetes resource type available at apiVersion";
        };
        metadata.name = lib.mkOption {
          type = lib.types.str;
          default = name;
          example = "my-helm-repository";
          description = lib.mdDoc "The name of the helm release";
        };
        metadata.namespace = lib.mkOption {
          type = lib.types.enum cfg.namespaces.all;
          default = name;
          example = "my-namespace";
          description = lib.mdDoc "The namespace for this helm release";
        };
        spec.chart.spec = {
          chart = lib.mkOption {
            type = lib.types.str;
            default = name;
            example = "kube-prometheus-stack";
            description = lib.mdDoc "Name of the chart from the source repository";
          };
          reconcileStrategy = lib.mkOption {
            type = lib.types.str;
            default = "ChartVersion";
            description = lib.mdDoc "TODO what does this actually do?";
          };
          version = lib.mkOption {
            type = lib.types.str;
            example = "1.0.2";
            description = lib.mdDoc "Version of the chart from the source repository";
          };
          sourceRef.kind = lib.mkOption {
            type = lib.types.str;
            default = "HelmRepository";
            example = "MyHelmRepository";
            description = lib.mdDoc "Type of source helm repository";
          };
          sourceRef.name = lib.mkOption {
            type = lib.types.str;
            default = config.metadata.namespace;
            example = "my-helm-repository";
            description = lib.mdDoc "Name of source helm repository";
          };
        };
        spec.dependsOn = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "my-other-upstream-release";
          description = lib.mdDoc "Name of another release that must be deployed before this one";
        };
        spec.interval = lib.mkOption {
          type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
          default = "1m0s";
          example = "23h59m59s";
          description = lib.mdDoc "Interval for syncing with repository";
        };
        spec.values = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
          example = {
            global.postgresPassword = "my-password";
            auth.username = "admin";
          };
          description = lib.mdDoc "Configuration overrides for helm chart";
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
