{nix, ...}: with nix; let
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
    affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = toList {
      matchExpressions = toList {
        key = "node-role.kubernetes.io/control-plane";
        operator = "Exists";
      };
    };
    tolerations = [
      {key = "CriticalAddonsOnly"; operator = "Exists";}
      {key = "node-role.kubernetes.io/control-plane"; operator = "Exists"; effect = "NoSchedule";}
    ];
    topologySpreadConstraints = toList {
      maxSkew = 1;
      topologyKey = "kubernetes.io/hostname";
      whenUnsatisfiable = "DoNotSchedule";
      labelSelector.matchLabels."app.kubernetes.io/instance" = "coredns";
    };
    prometheus.service.enabled = true;
    prometheus.monitor.enabled = true;
    hpa.enabled = true;
  };
  release = {inherit namespace chart values;};
in {
  perSystem.dotfiles.helm = {
    coredns-bootstrap = recursiveUpdate release {
      bootstrap = true;
      # values.readinessProbe.enabled = false;
      # values.livenessProbe.enabled = false;
    };
    coredns = release;
  };
}
