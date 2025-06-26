{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.coredns.enable = lib.mkEnableOption "coredns";
    config = lib.mkIf config.services.coredns.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.coredns = pkgs.dockerTools.pullImage {
          imageName = "coredns/coredns";
          imageDigest = "sha256:40384aa1f5ea6bfdc77997d243aec73da05f27aed0c5e9d65bfa98933c519d97";
          hash = "sha256-owXsrTKUtV/6fPlWRc1YmELlOzpdkSEHwQiFLEvR+O0=";
          finalImageTag = "1.12.0";
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.coredns = {
          namespace = "kube-system";
          chart = helm.fetch {
            repo = "https://coredns.github.io/helm";
            chart = "coredns";
            version = "1.39.2";
            sha256 = "sha256-801r6B6OTNB+Ds+G8vRi8ReXN4bLzb6L/8N+Ufu9P5k=";
          };
          values = {
            service.clusterIP = "10.43.0.10";
            # servers = lib.toList {
            #   zones = lib.toList {
            #     zone = ".";
            #     use_tcp = true;
            #   };
            #   port = 53;
            #   plugins = [
            #     {name = "errors";}
            #     {
            #       name = "health";
            #       configBlock = ''
            #         lameduck 10s
            #       '';
            #     }
            #     {name = "ready";}
            #     {
            #       name = "kubernetes";
            #       parameters = "cluster.local in-addr.arpa ip6.arpa";
            #       configBlock = ''
            #         pods insecure
            #         fallthrough in-addr.arpa ip6.arpa
            #         ttl 30
            #       '';
            #     }
            #     {
            #       name = "forward";
            #       parameters = "tailscale.trdos.me /etc/resolv.conf";
            #     }
            #     {
            #       name = "forward";
            #       parameters = ". 1.1.1.1";
            #     }
            #     {
            #       name = "prometheus";
            #       parameters = "0.0.0.0:9153";
            #     }
            #     {
            #       name = "cache";
            #       parameters = 30;
            #     }
            #     {name = "loop";}
            #     {name = "reload";}
            #     {name = "loadbalance";}
            #   ];
            # };
            # TODO what else do I need to configure?
            # fullnameOverride = "coredns";
            # serviceAccount.create = true;
            # affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = lib.toList {
            #   matchExpressions = lib.toList {
            #     key = "node-role.kubernetes.io/control-plane";
            #     operator = "Exists";
            #   };
            # };
            # tolerations = [
            #   {
            #     key = "CriticalAddonsOnly";
            #     operator = "Exists";
            #   }
            #   {
            #     key = "node-role.kubernetes.io/control-plane";
            #     operator = "Exists";
            #     effect = "NoSchedule";
            #   }
            # ];
            # topologySpreadConstraints = lib.toList {
            #   maxSkew = 1;
            #   topologyKey = "kubernetes.io/hostname";
            #   whenUnsatisfiable = "DoNotSchedule";
            #   labelSelector.matchLabels."app.kubernetes.io/instance" = "coredns";
            # };
            # prometheus.service.enabled = true;
            # prometheus.monitor.enabled = true;
            # hpa.enabled = true;
          };
        };
      };
    };
  };
}
