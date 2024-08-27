{config, ...}: let
  inherit (config.dotfiles) domain;
in {
  # NOTE https://github.com/cilium/cilium
  perSystem.dotfiles.helm.cilium = {
    bootstrap = true;
    namespace = "network";
    chart = {
      repo = "https://helm.cilium.io";
      chart = "cilium";
      version = "1.16.1";
      sha256 = "+51oGLnIAzeJd+yPTXOOhvcR5UNMOPAxd4Hu6LpvhbU=";
    };
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
          className = "internal";
          hosts = ["hubble.${domain}"];
        };
      };
      operator.rollOutPods = true;
      operator.prometheus.serviceMonitor.enabled = true;
      operator.dashboards.enabled = true;
      prometheus.enabled = true;
      prometheus.serviceMonitor.enabled = true;
      prometheus.serviceMonitor.trustCRDsExist = true;
      dashboards.enabled = true;
      autoDirectNodeRoutes = true;
      bandwidthManager.enabled = true;
      bandwidthManager.bbr = true;
      bpf.masquerade = true;
      bpf.tproxy = true;
      cgroup.autoMount.enabled = false;
      cgroup.hostRoot = "/sys/fs/cgroup";
      cluster.name = "prod";
      cluster.id = 1;
      # TODO should I take advantage of network bonding?
      # NOTE https://search.nixos.org/options?channel=unstable&show=networking.bonds&from=0&size=50&sort=alpha_asc&type=packages&query=bond
      # NOTE https://www.kernel.org/doc/Documentation/networking/bonding.txt
      # NOTE https://wiki.debian.org/Bonding#Bonding-1
      # devices = "bond+";
      # devices = "enp+";
      endpointRoutes.enabled = true;
      envoy.enabled = false;
      ipam.mode = "kubernetes";
      # TODO should I use a native routing CIDR
      # ipv4NativeRoutingCIDR = "";
      # TODO is this correct? do I even have to set this?
      k8sServiceHost = "127.0.0.1";
      k8sServicePort = 6443;
      kubeProxyReplacement = true;
      kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256";
      l2announcements.enabled = true;
      loadBalancer.algorithm = "maglev";
      loadBalancer.mode = "dsr";
      localRedirectPolicy = true;
      rollOutCiliumPods = true;
      routingMode = "native";
    };
  };
}
