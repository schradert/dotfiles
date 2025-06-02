{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkForce mkIf toList mapAttrs' nameValuePair;
    namespace = "security";
    name = "external-secrets-kubernetes";
  in {
    options.services.external-secrets.enable = mkEnableOption "external-secrets";
    config = mkIf config.services.external-secrets.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.external-secrets = pkgs.dockerTools.pullImage {
          imageName = "oci.external-secrets.io/external-secrets/external-secrets";
          imageDigest = "sha256:6d7fcb0f6f3c40bf5f5980b9b9b0ef6bf89de7c1867a0de8d463b78024b80890";
          hash = "sha256-YGiCb77W7CLtYrW2OoBT0QTp+8sPIndKbv5QeU2y4n8=";
          finalImageTag = "v0.15.1";
        };
      };
      kubenix = {
        config,
        helm,
        ...
      }: {
        canivete.ifd.crds = {
          clustersecretstores = "external-secrets.io/v1beta1/ClusterSecretStore";
          externalsecrets = "external-secrets.io/v1beta1/ExternalSecret";
        };
        # NOTE IFD upstream module will prefer the first version (v1alpha1) when merging so we override
        kubernetes.customTypes = {
          clustersecretstores.version = mkForce "v1beta1";
          externalsecrets.version = mkForce "v1beta1";
        };
        kubernetes.resources.kappconfig.kapp.rebaseRules = toList {
          path = ["data"];
          type = "copy";
          sources = ["existing"];
          resourceMatchers = toList {
            kindNamespaceNameMatcher = {
              kind = "Secret";
              inherit namespace;
              name = "external-secrets-webhook";
            };
          };
        };
        kubernetes.helm.releases.external-secrets = {
          inherit namespace;
          chart = helm.fetch {
            repo = "https://charts.external-secrets.io";
            chart = "external-secrets";
            version = "0.15.1";
            sha256 = "sha256-mLzcibX7bEbo0Jp0OzVJ2BDUGI3ffiVcSJN0Gf1KXEA=";
          };
          values.serviceMonitor.enabled = true;
          extraResources = {
            clustersecretstores = mapAttrs' (ns: _:
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
            config.kubernetes.resources.namespaces;
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
