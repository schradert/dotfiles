{
  config,
  lib,
  ...
}: let
  inherit (lib) pipe filterAttrs mapAttrsToList concatStringsSep mkIf recursiveUpdate toList;
  # NOTE https://github.com/cilium/cilium
  inherit (config.dotfiles) domain;
  # most are eno1, sirver = eno4, axolotl = enp0s31f6
  devices = "en+";
  namespace = "kube-system";
  chart = {
    repo = "https://helm.cilium.io";
    chart = "cilium";
    version = "1.16.1";
    sha256 = "+51oGLnIAzeJd+yPTXOOhvcR5UNMOPAxd4Hu6LpvhbU=";
  };
  values = {
    # Deactivate defaults
    cni.exclusive = false;
    envoy.enabled = false;

    bandwidthManager.enabled = true;
    bandwidthManager.bbr = true;
    bpf.masquerade = true;
    bpf.tproxy = true;
    cluster.name = "prod";
    cluster.id = 1;
    endpointRoutes.enabled = true;
    ipam.mode = "kubernetes";
    localRedirectPolicy = true;
    l2announcements.enabled = true;
    operator.rollOutPods = true;
    rollOutCiliumPods = true;

    # Kube-Proxy replacement
    inherit devices;
    kubeProxyReplacement = true;
    kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256";
    k8sServiceHost = pipe config.canivete.deploy.nixos.nodes [
      (filterAttrs (_: node: with node.profiles.system.raw.config; dotfiles.kubernetes.enable && services.k3s.role == "server"))
      (mapAttrsToList (_: node: node.install.host))
      (concatStringsSep ",")
    ];
    k8sServicePort = 6443;
    loadBalancer.algorithm = "maglev";

    # TODO Native Routing without BGP daemon
    # NOTE services just seem to fail all of the checks
    # autoDirectNodeRoutes = true;
    # ipv4NativeRoutingCIDR = "10.42.0.0/16";
    # routingMode = "native";
    # socketLB.hostNamespaceOnly = true;
    # NOTE Direct Server Return requires native routing
    # loadBalancer.mode = "dsr";
    # NOTE the cilium-agent pods fail to deploy like this
    # loadBalancer.acceleration = "native";
  };
  release = {inherit namespace chart values;};
in {
  canivete.deploy.nixos.modules.cilium = {config, ...}: {
    # NOTE https://docs.cilium.io/en/stable/operations/system_requirements
    config = mkIf config.dotfiles.kubernetes.enable {
      boot.blacklistedKernelModules = ["netfilter"];
      boot.kernelModules = ["cls_bpf" "sch_ingress" "crypto_user"];
      networking.firewall.enable = false;
    };
  };
  # Cilium chart has no way to include CRDs...
  perSystem.canivete.kubenix.clusters.prod.modules.cilium-types.kubernetes.customTypes = [
    {
      attrName = "ciliuml2announcementpolicies";
      group = "cilium.io";
      kind = "CiliumL2AnnouncementPolicy";
      version = "v2alpha1";
    }
    {
      attrName = "ciliumloadbalancerippools";
      group = "cilium.io";
      kind = "CiliumLoadBalancerIPPool";
      version = "v2alpha1";
    }
  ];
  perSystem.dotfiles.helm = {
    cilium-bootstrap = release // {bootstrap = true;};
    cilium = recursiveUpdate release {
      values = {
        hubble = {
          metrics.enabled = ["dns:query;ignoreAAAA" "drop" "tcp" "flow" "port-distribution" "icmp" "http"];
          metrics.serviceMonitor.enabled = true;
          metrics.dashboards.enabled = true;
          relay = {
            enabled = true;
            rollOutPods = true;
            prometheus.enabled = true;
            prometheus.serviceMonitor.enabled = true;
          };
          ui.enabled = true;
          ui.rollOutPods = true;
          ui.ingress = {
            enabled = true;
            className = "external";
            hosts = ["hubble.${domain}"];
            annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
            annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
            annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
          };
        };
        operator.prometheus.serviceMonitor.enabled = true;
        operator.dashboards.enabled = true;
        prometheus.enabled = true;
        prometheus.serviceMonitor.enabled = true;
        prometheus.serviceMonitor.trustCRDsExist = true;
        dashboards.enabled = true;
      };
      resources.ciliuml2announcementpolicies.l2.spec = {
        loadBalancerIPs = true;
        interfaces = [devices];
        nodeSelector.matchLabels."kubernetes.io/os" = "linux";
      };
      resources.ciliumloadbalancerippools.l2.spec = {
        allowFirstLastIPs = "Yes";
        blocks = toList {
          start = "192.168.50.200";
          stop = "192.168.50.209";
        };
      };
    };
  };
}
