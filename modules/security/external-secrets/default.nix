{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf toList mapAttrs' nameValuePair;
    namespace = "security";
    name = "external-secrets-kubernetes";
    appVersion = "v0.18.2";
    image = {
      imageName = "oci.external-secrets.io/external-secrets/external-secrets";
      imageDigest = "sha256:87615c878c0528ea994538d2a6ed87931f8389b9e145f4422891b3ba06430cd7";
      hash = "sha256-fALEY5ZA0oHRpX85GsFv1iq5rA0Z3P9cNiWRzxtKHd4=";
      finalImageTag = appVersion;
    };
  in {
    options.services.external-secrets.enable = mkEnableOption "external-secrets";
    config = mkIf services.external-secrets.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.external-secrets = pkgs.dockerTools.pullImage image;};
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        # Can't render with gomplate because "function 'toYaml' not defined"
        dotfiles.crds.external-secrets = {
          prefix = "config/crds/bases";
          src = pkgs.fetchFromGitHub {
            owner = "external-secrets";
            repo = "external-secrets";
            rev = appVersion;
            hash = "sha256-ZOa6tEHltl14gSLlnmze0m9JVYaY47v7OI8M9B7CpyQ=";
          };
        };
        applications.external-secrets = {
          namespace = "security";
          helm.releases.external-secrets = {
            chart = charts.external-secrets.external-secrets;
            values = {
              serviceMonitor.enabled = services.prometheus.enable;
              image = {
                repository = image.imageName;
                pullPolicy = "Never";
                tag = image.finalImageTag;
              };
              webhook.image = {
                repository = image.imageName;
                pullPolicy = "Never";
                tag = image.finalImageTag;
              };
              certController.image = {
                repository = image.imageName;
                pullPolicy = "Never";
                tag = image.finalImageTag;
              };
            };
          };
          resources = {
            clusterSecretStores =
              mapAttrs' (ns: _:
                nameValuePair "kubernetes-${ns}" {
                  spec.provider.kubernetes = {
                    auth.serviceAccount = {inherit name namespace;};
                    # TODO make one for all the namespaces
                    remoteNamespace = "default";
                    server.caProvider = {
                      type = "ConfigMap";
                      name = "kube-root-ca.crt";
                      inherit namespace;
                      key = "ca.crt";
                    };
                  };
                  # TODO is this sufficient for all namespaces?
                })
              # TODO dynamic
              {
                cicd = {};
                monitoring = {};
                security = {};
                storage = {};
                network = {};
              };
            serviceAccounts.${name} = {};
            clusterRoles.${name}.rules = [
              {
                apiGroups = [""];
                resources = ["secrets"];
                verbs = ["get" "list" "watch"];
              }
              {
                # TODO is this actually necessary?
                apiGroups = ["authorization.k8s.io"];
                resources = ["selfsubjectrulesreviews"];
                verbs = ["create"];
              }
            ];
            clusterRoleBindings.${name} = {
              roleRef = {
                inherit name;
                kind = "ClusterRole";
                apiGroup = "rbac.authorization.k8s.io";
              };
              subjects = toList {
                inherit name namespace;
                kind = "ServiceAccount";
              };
            };
          };
        };
      };
    };
  };
}
