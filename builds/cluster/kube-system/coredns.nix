{lib, ...}: {
  perSystem.canivete.kubenix.helm.coredns = {
    namespace = "kube-system";
    chart = {
      repo = "https://coredns.github.io/helm";
      chart = "coredns";
      version = "1.32.0";
      sha256 = "/emXMPoZMa2CICJ9jgNdih27x/4v7WFHR4rkdMdyAFg=";
    };
    values = {
      fullnameOverride = "coredns";
      serviceAccount.create = true;
      service.clusterIP = "10.43.0.10";
      affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = lib.toList {
        matchExpressions = lib.toList {
          key = "node-role.kubernetes.io/control-plane";
          operator = "Exists";
        };
      };
      tolerations = [
        {
          key = "CriticalAddonsOnly";
          operator = "Exists";
        }
        {
          key = "node-role.kubernetes.io/control-plane";
          operator = "Exists";
          effect = "NoSchedule";
        }
      ];
      topologySpreadConstraints = lib.toList {
        maxSkew = 1;
        topologyKey = "kubernetes.io/hostname";
        whenUnsatisfiable = "DoNotSchedule";
        labelSelector.matchLabels."app.kubernetes.io/instance" = "coredns";
      };
      prometheus.service.enabled = true;
      prometheus.monitor.enabled = true;
      hpa.enabled = true;
    };
  };
}
