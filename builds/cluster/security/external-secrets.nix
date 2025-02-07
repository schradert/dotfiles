{lib, ...}: let
  name = "external-secrets-kubernetes";
  namespace = "security";
  namespaces = ["home" "kube-system" "office" "media" "storage"];
  namespaceModules = lib.forEach namespaces (ns: {
    clustersecretstores."kubernetes-${ns}" = {
      spec.provider.kubernetes = {
        auth.serviceAccount = {inherit name namespace;};
        remoteNamespace = ns;
        server.caProvider = {
          type = "ConfigMap";
          name = "kube-root-ca.crt";
          inherit namespace;
          key = "ca.crt";
        };
      };
    };
  });
  commonModule = {
    serviceAccounts.${name} = {};
    clusterRoles.${name}.rules = [
      {
        apiGroups = [""];
        resources = ["secrets"];
        verbs = ["get" "list" "watch"];
      }
      {
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
      subjects = lib.toList {
        inherit name namespace;
        kind = "ServiceAccount";
      };
    };
  };
in {
  perSystem.dotfiles.helm.external-secrets = {
    inherit namespace;
    chart = {
      repo = "https://charts.external-secrets.io";
      chart = "external-secrets";
      version = "0.10.3";
      sha256 = "sC4APZ5B5zdp2ZF29YZjT2EdaTacR43pnroQqE4TyNQ=";
    };
    values.serviceMonitor.enabled = true;
    # TODO can I use a single ClusterSecretStore?
    resources = lib.mkMerge (namespaceModules ++ [commonModule]);
  };
}
