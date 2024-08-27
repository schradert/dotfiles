{nix, ...}: with nix; {
  perSystem.dotfiles.helm.coredns = {
    bootstrap = true;
    namespace = "kube-system";
    chart = {
      repo = "https://coredns.github.io/helm";
      chart = "coredns";
      version = "1.32.0";
      sha256 = "/emXMPoZMa2CICJ9jgNdih27x/4v7WFHR4rkdMdyAFg=";
    };
    values = {
      fullnameOverride = "coredns";
      replicaCount = 3;
      k8sAppLabelOverride = "kube-dns";
      serviceAccount.create = true;
      service.name = "kube-dns";
      service.clusterIP = "10.43.0.10";
      servers = toList {
        zones = toList {
          zone = ".";
          scheme = "dns://";
          use_tcp = true;
        };
        port = 53;
        plugins = [
          {name = "errors";}
          {name = "ready";}
          {name = "loop";}
          {name = "reload";}
          {name = "loadbalance";}
          {name = "health"; configBlock = "\nlameduck 5s";}
          {name = "log"; configBlock = "\nclass error";}
          {name = "prometheus"; parameters = "0.0.0.0:9153";}
          {name = "kubernetes"; parameters = "cluster.local in-addr.arpa ip6.arpa"; configBlock = "\npods insecure\nfallthrough in-addr.arpa ip4.arpa";}
          {name = "forward"; parameters = ". /etc/resolv.conf";}
          {name = "cache"; parameters = 30;}
        ];
      };
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
    };
  };
}
