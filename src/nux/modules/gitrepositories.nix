{ config, lib, pkgs, ... }:
{
   options.repositories.git = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
      options = {
        apiVersion = lib.mkOption {
          type = lib.types.str;
          default = "source.toolkit.fluxcd.io/v1";
          example = "source.toolkit.fluxcd.io/v1beta2";
          description = lib.mdDoc "Kubernetes apiVersion for resource";
        };
        kind = lib.mkOption {
          type = lib.types.str;
          default = "GitRepository";
          example = "MyGitRepository";
          description = lib.mdDoc "Kubernetes resource type available at apiVersion";
        };
        metadata.name = lib.mkOption {
          type = lib.types.str;
          default = name;
          example = "my-helm-repository";
          description = lib.mdDoc "The name of the git repository";
        };
        metadata.namespace = lib.mkOption {
          type = lib.types.enum config.namespaces.all;
          default = name;
          example = "my-namespace";
          description = lib.mdDoc "The namespace for this git repository reference";
        };
        spec.interval = lib.mkOption {
          type = lib.types.strMatching "^([0-9]+h)?([0-5]?[0-9]m)?([0-5]?[0-9]+s)?$";
          default = "1m0s";
          example = "23h59m59s";
          description = lib.mdDoc "Interval for syncing with repository";
        };
        spec.url = lib.mkOption {
          type = lib.types.strMatching "^https://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$";
          example = "https://github.com/organization/repository";
          description = lib.mdDoc "URL of git repository";
        };
        spec.ref.branch = lib.mkOption {
          type = lib.types.str;
          default = "main";
          example = "trunk";
          description = lib.mdDoc "Reference to relevant git branch in the repository";
        };
      };
    }));
    default = {};
    description = lib.mdDoc "FluxCD GitRepository resources";
  };
  config.resources = builtins.attrValues config.repositories.git;
}
