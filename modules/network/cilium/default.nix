{
  perSystem = {pkgs, ...}: {
    canivete.devShells.shells.default.packages = [pkgs.cilium-cli];
  };
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkForce mkMerge toList pipe hasSuffix;
  in {
    options.services.cilium.enable = mkEnableOption "Cilium CNI";
    config = mkMerge [
      {
        nixos = {
          config,
          pkgs,
          ...
        }: {
          options.dotfiles.cilium.enable = mkEnableOption "Cilium requirements";
          config = mkIf config.dotfiles.cilium.enable {
            boot.blacklistedKernelModules = ["netfilter"];
            boot.kernelModules = ["cls_bpf" "sch_ingress" "crypto_user" "iptable_raw" "xt_socket"];
            canivete.kubernetes.images = {
              cilium-operator = pkgs.dockerTools.pullImage {
                imageName = "quay.io/cilium/operator-generic";
                imageDigest = "sha256:f954c97eeb1b47ed67d08cc8fb4108fb829f869373cbb3e698a7f8ef1085b09e";
                hash = "sha256-dDP8xBSqHiW/4Wxc2YlGOkM81zlfIbx2YCsS0vo3lvE=";
                finalImageTag = "v1.17.5";
              };
              cilium = pkgs.dockerTools.pullImage {
                imageName = "quay.io/cilium/cilium";
                imageDigest = "sha256:baf8541723ee0b72d6c489c741c81a6fdc5228940d66cb76ef5ea2ce3c639ea6";
                hash = "sha256-KdIHQGk2fqCOM35/WkMSA/AqBbrbji6rIoml0VBO4Ds=";
                finalImageTag = "v1.17.5";
              };
            };
            # TODO build https://github.com/hengyoush/kyanos
            environment.systemPackages = [pkgs.bpftop];
            # networking.firewall.enable = mkForce false;
          };
        };
      }
      (mkIf config.services.cilium.enable {
        kubenix = {
          canivete,
          helm,
          pkgs,
          ...
        }: {
          canivete.ifd.crds.ciliumloadbalancerippools = "cilium.io/v2alpha1/CiliumLoadBalancerIPPool";
          kubernetes.imports =
            pipe {
              owner = "cilium";
              repo = "cilium";
              rev = "v1.17.5";
              hash = "sha256-frpu1kJICbZFwmH/KQ2pZHcS2M+XvLvxZpzVxok2eM8=";
            } [
              pkgs.fetchFromGitHub
              (source: source + "/pkg/k8s/apis/cilium.io/client/crds")
              (canivete.filesets.everything (name: _: hasSuffix ".yaml" name))
            ];
          kubernetes.resources.ciliumloadbalancerippools.main = {
            metadata.annotations."kapp.k14s.io/change-group.cilium" = "cilium";
            spec.blocks = [
              {
                start = "100.64.1.0";
                stop = "100.64.1.255";
              }
              # FIXME avoid hardcoding external IP
              # {
              #   start = "157.131.153.137";
              #   stop = "157.131.153.137";
              # }
            ];
          };
          kubernetes.resources.kappconfig.kapp.changeGroupBindings = toList {
            name = "not-cilium";
            resourceMatchers = toList {notMatcher.matcher.hasAnnotationMatcher.keys = ["kapp.k14s.io/change-group.cilium"];};
          };
          kubernetes.helm.releases.cilium = {
            namespace = "kube-system";
            chart = helm.fetch {
              repo = "https://helm.cilium.io";
              chart = "cilium";
              version = "1.17.5";
              sha256 = "sha256-94xCDaau6blpHx+GmlCmR4QmNfV2b27lMM9hYuDd0do=";
            };
            overrides = toList {
              metadata.annotations."kapp.k14s.io/change-group.cilium" = "cilium";
              metadata.annotations."kapp.k14s.io/change-rule.cilium" = "upsert before upserting not-cilium";
            };
            values = {
              # autoDirectNodeRoutes = true;
              # bpf.masquerade = true;
              cgroup.autoMount.enabled = false;
              cgroup.hostRoot = "/sys/fs/cgroup";
              # devices = ["br0"];
              # ipam.operator.clusterPoolIPv4PodCIDRList = ["10.42.0.0/16"];
              # ipv4NativeRoutingCIDR = "10.42.0.0/16";
              kubeProxyReplacement = true;
              k8sServiceHost = "192.168.50.185";
              k8sServicePort = 6443;
              operator.replicas = 1;
              # routingMode = "native";
              #
              tunnelProtocol = "geneve";

              # TODO cluster-pool if better
              # ipam.operator.clusterPoolIPv4PodCIDRList = ["10.42.0.0/16"];
              # ipv4NativeRoutingCIDR = "10.42.0.0/16";
              # k8s.requireIPv4PodCIDR = true;

              # devices = ["eno1" "br0"];
              # # devices = ["eno1" "br0" "tailscale0"];
              # # devices = ["eno1" "br0" "tailscale0" "cilium_host"];
              # # nodePort.directRoutingDevice = "tailscale0";

              # autoDirectNodeRoutes = true;
              # bandwidthManager.bbr = true;
              # bandwidthManager.enabled = true;
              # bgpControlPlane.enabled = true;
              # bpf.datapathMode = "netkit";
              # bpf.masquerade = true;
              # bpf.preallocateMaps = true;
              # bpfClockProbe = true;
              # cgroup.autoMount.enabled = false;
              # cgroup.hostRoot = "/sys/fs/cgroup";
              # cluster.id = 1;
              # cluster.name = "main";
              # cni.exclusive = false;
              # dashboards.enabled = true;
              # dashboards.annotations.grafana_folder = "Cilium";
              # endpointRoutes.enabled = true;
              # envoy.enabled = true;
              # envoy.rollOutPods = true;
              # gatewayAPI.enabled = true;
              # gatewayAPI.enableAlpn = true;
              # gatewayAPI.xffNumTrustedHops = 1;
              # hubble = {
              #   # enabled = true;
              #   metrics.enabled = [
              #     "dns:query"
              #     # "dns:query;ignoreAAAA"
              #     "drop"
              #     "tcp"
              #     "flow"
              #     "port-distribution"
              #     "icmp"
              #     "http"
              #   ];
              #   # metrics.serviceMonitor.enabled = true;
              #   metrics.dashboards.enabled = true;
              #   # relay.enabled = true;
              #   relay.rollOutPods = true;
              #   # NOTE relay.prometheus.enabled = true?
              #   # relay.prometheus.serviceMonitor.enabled = true;
              #   # ui.enabled = true;
              #   ui.rollOutPods = true;
              #   # TODO conver this to gateway
              #   # ui.ingress = {
              #   #   enabled = true;
              #   #   className = "internal";
              #   #   hosts = ["hubble.${domain}"];
              #   #   annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
              #   #   annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
              #   #   annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              #   # };
              # };
              # image.useDigest = false;
              # ipam.mode = "kubernetes";
              # ipv4NativeRoutingCIDR = "10.42.0.0/16";
              # k8sServiceHost = "127.0.0.1";
              # k8sServicePort = 6443;
              # kubeProxyReplacement = true;
              # kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256";
              # l2announcements.enabled = false;
              # loadBalancer.algorithm = "maglev";
              # loadBalancer.mode = "dsr";
              # localRedirectPolicy = true;
              # operator = {
              #   dashboards.enabled = true;
              #   dashboards.annotations.grafana_folder = "Cilium";
              #   image.useDigest = false;
              #   prometheus.enabled = true;
              #   # prometheus.serviceMonitor.enabled = true;
              #   replicas = 1;
              #   # replicas = 2;
              #   rollOutPods = true;
              #   tolerations = [];
              # };
              # prometheus.enabled = true;
              # # prometheus.serviceMonitor.enabled = true;
              # prometheus.serviceMonitor.trustCRDsExist = true;
              # rollOutCiliumPods = true;
              # routingMode = "native";
              # securityContext.capabilities.ciliumAgent = [
              #   "CHOWN"
              #   "KILL"
              #   "NET_ADMIN"
              #   "NET_RAW"
              #   "IPC_LOCK"
              #   "SYS_ADMIN"
              #   "SYS_RESOURCE"
              #   "PERFMON"
              #   "BPF"
              #   "DAC_OVERRIDE"
              #   "FOWNER"
              #   "SETGID"
              #   "SETUID"
              # ];
              # securityContext.capabilities.cleanCiliumState = [
              #   "NET_ADMIN"
              #   "SYS_ADMIN"
              #   "SYS_RESOURCE"
              # ];
            };
          };
        };
      })
    ];
  };
}
