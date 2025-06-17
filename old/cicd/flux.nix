let
  repo = "https://fluxcd-community.github.io/helm-charts";
in {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [repo];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config.services) fluxcd;
    inherit (lib) mkEnableOption mkIf mkOption types;
    inherit (types) enum str submodule;
  in {
    options.services.fluxcd = {
      enable = mkEnableOption "Flux2 CD deployment";
      repo = mkOption {
        type = submodule {
          options = {
            auth = mkOption {type = enum ["ssh"];};
            domain = mkOption {type = str;};
            owner = mkOption {type = str;};
            repo = mkOption {type = str;};
            branch = mkOption {type = str;};
          };
        };
      };
    };
    config = mkIf fluxcd.enable {
      opentofu = mkIf (fluxcd.repo.domain == "github.com") {
        plugins = ["hashicorp/tls" "integrations/github"];
        modules.resource = {
          null_resource.kubernetes.depends_on = ["github_repository_deploy_key.flux"];
          tls_private_key.flux.algorithm = "ED25519";
          github_repository_deploy_key.flux = {
            key = "\${ tls_private_key.flux.public_key_openssh }";
            repository = fluxcd.repo.repo;
            read_only = true;
            title = "FluxCD";
          };
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.resources.gitrepositories.github = {
          metadata.namespace = "cicd";
          spec.interval = "5m0s";
          spec.url = with fluxcd.repo; "ssh://git@${domain}:22/${owner}/${repo}.git";
          spec.ref.branch = fluxcd.repo.branch;
        };
        kubernetes.helm.releases.fluxcd = {
          namespace = "cicd";
          chart = helm.fetch {
            inherit repo;
            chart = "flux2";
            version = "2.15.0";
            sha256 = "sha256-U33lQ6dG8LMQemEI5ww0gySOsvSjA3nXfD6AGF/isxo=";
          };
          values = {
            # NOTE only controllers needed for now are source and kustomize
            # TODO should I replace the controllers?
            # helmController.create = false;
            # imageAutomationController.create = false;
            # imageReflectionController.create = false;
            # notificationController.create = false;
            # prometheus.podMonitor.create = true;
          };
        };
      };
    };
  };
}
