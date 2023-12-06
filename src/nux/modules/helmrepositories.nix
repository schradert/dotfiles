{ config, lib, pkgs, ... }:
{
  options.repositories.helm = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
      options = {
        apiVersion = lib.mkOption {
          type = lib.types.str;
          default = "source.toolkit.fluxcd.io/v1beta2";
          example = "source.toolkit.fluxcd.io/v1";
          description = lib.mdDoc "Kubernetes apiVersion for resource";
        };
        kind = lib.mkOption {
          type = lib.types.str;
          default = "HelmRepository";
          example = "MyHelmRepository";
          description = lib.mdDoc "Kubernetes resource type available at apiVersion";
        };
        metadata.name = lib.mkOption {
          type = lib.types.str;
          default = name;
          example = "my-helm-repository";
          description = lib.mdDoc "The name of the helm repository";
        };
        metadata.namespace = lib.mkOption {
          type = lib.types.enum config.namespaces.all;
          default = name;
          example = "my-namespace";
          description = lib.mdDoc "The namespace for this helm repository reference";
        };
        spec.interval = lib.mkOption {
          type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
          default = "1m0s";
          example = "23h59m59s";
          description = lib.mdDoc "Interval for syncing with repository";
        };
        spec.type = lib.mkOption {
          type = lib.types.enum ["http" "oci"];
          default = "http";
          example = "oci";
          description = lib.mdDoc "HelmRepository type (e.g. http, oci, etc.)";
        };
        spec.url = lib.mkOption {
          type = lib.types.strMatching "^(oci|https)://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$";
          example = "https://traefik.github.io/charts";
          description = lib.mdDoc "URL of helm chart repository";
        };
      };
    }));
    default = {};
    description = lib.mdDoc "FluxCD HelmRepository resources";
  };
  config.resources = builtins.attrValues config.repositories.helm;
}
