{
  perSystem = {pkgs, ...}: {
    canivete.devShells.shells.default.packages = [pkgs.cilium-cli];
  };
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mapAttrs mkEnableOption mkIf mkForce mkMerge;
    appVersion = "v1.17.6";
    images = {
      cilium = {
        imageName = "quay.io/cilium/cilium";
        imageDigest = "sha256:544de3d4fed7acba72758413812780a4972d47c39035f2a06d6145d8644a3353";
        hash = "sha256-lt9dAJ+tcnneMvekzQh6astsHxbgdmoLwwUH0iN28uA=";
        finalImageTag = appVersion;
      };
      cilium-envoy = {
        imageName = "quay.io/cilium/cilium-envoy";
        imageDigest = "sha256:f26154a54c881c085b2a868f4719b31ae02e2be0bad001a67ac7462ba2e5b0e9";
        hash = "sha256-Zs3ph9GXGTrima9gk15501jC6aJmgh2Zqveuc+D9zMM=";
        finalImageTag = "v1.34.3-1753136543-8da82c827e7e5b2ad5f107f7f485073bcb7a797f";
      };
      cilium-hubble-relay = {
        imageName = "quay.io/cilium/hubble-relay";
        imageDigest = "sha256:7d17ec10b3d37341c18ca56165b2f29a715cb8ee81311fd07088d8bf68c01e60";
        hash = "sha256-d6iOo/uZ8bFLq9Jxtypvc/P7lhuSVTdlV4f8dH541wc=";
        finalImageTag = appVersion;
      };
      cilium-hubble-ui-backend = {
        imageName = "quay.io/cilium/hubble-ui-backend";
        imageDigest = "sha256:a034b7e98e6ea796ed26df8f4e71f83fc16465a19d166eff67a03b822c0bfa15";
        hash = "sha256-XUv3mLvCn26oEY9CR/twYKVzUrAkS3NkaaB0oxFkybQ=";
        finalImageTag = "v0.13.2";
      };
      cilium-hubble-ui-frontend = {
        imageName = "quay.io/cilium/hubble-ui";
        imageDigest = "sha256:9e37c1296b802830834cc87342a9182ccbb71ffebb711971e849221bd9d59392";
        hash = "sha256-KJ9c/QBibQXE0XCbg1zw5LxzqSKIS/x8MC7dY/5r8qY=";
        finalImageTag = "v0.13.2";
      };
      cilium-operator = {
        imageName = "quay.io/cilium/operator-generic";
        imageDigest = "sha256:91ac3bf7be7bed30e90218f219d4f3062a63377689ee7246062fa0cc3839d096";
        hash = "sha256-d6iOo/uZ8bFLq9Jxtypvc/P7lhuSVTdlV4f8dH541wc=";
        finalImageTag = appVersion;
      };
    };
    pinImage = image: {
      repository = image.imageName;
      tag = image.finalImageTag;
      pullPolicy = "Never";
      digest = image.imageDigest;
      # TODO why doesn't it find the images by digest?
      useDigest = false;
    };
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
            canivete.kubernetes.images = mapAttrs (_: pkgs.dockerTools.pullImage) images;
            # Need Cilium DaemonSet images on all nodes before Spegel deployment will work
            services.k3s.images = lib.attrVals ["cilium" "cilium-envoy"] config.canivete.kubernetes.images;
            # TODO build https://github.com/hengyoush/kyanos
            environment.systemPackages = [pkgs.bpftop];
            networking.firewall.trustedInterfaces = ["cilium+" "lxc+"];
            # FIXME avoid disabling the firewall
            networking.firewall.enable = mkForce false;
            # TODO is this the best way to do the firewall for now?
            # networking.firewall.extraCommands = ''
            #   iptables -I INPUT -s 10.0.0.0/8 -j ACCEPT
            #   iptables -I OUTPUT -d 10.0.0.0/8 -j ACCEPT
            #   iptables -I FORWARD -s 10.0.0.0/8 -j ACCEPT
            #   iptables -I FORWARD -d 10.0.0.0/8 -j ACCEPT
            #   iptables -I FORWARD -s 10.0.0.0/8 -d 192.168.50.0/24 -j ACCEPT
            # '';
          };
        };
      }
      (mkIf config.services.cilium.enable {
        nixidy = {
          charts,
          pkgs,
          ...
        }: {
          dotfiles.crds.cilium = {
            install = true;
            prefix = "pkg/k8s/apis/cilium.io/client/crds";
            src = pkgs.fetchFromGitHub {
              owner = "cilium";
              repo = "cilium";
              rev = appVersion;
              hash = "sha256-aqXQ9BzWGGtb7MtNhRgYBqNaz5kT2enykof5k3/oSZM=";
            };
          };
          applications.cilium = {
            imports = [
              (mkIf config.services.prometheus.enable {
                dotfiles.bootstrap.exclude = builtins.map (name: "monitoring.coreos.com/v1/ServiceMonitor/${name}") [
                  "cilium-agent"
                  "cilium-envoy"
                  "cilium-operator"
                  "hubble-relay"
                ];
                helm.releases.cilium.values = {
                  envoy.prometheus.serviceMonitor.enabled = true;
                  hubble.metrics.serviceMonitor.enabled = true;
                  hubble.relay.prometheus.serviceMonitor.enabled = true;
                  operator.prometheus.serviceMonitor.enabled = true;
                  prometheus.serviceMonitor.enabled = true;
                  prometheus.serviceMonitor.trustCRDsExist = true;
                };
              })
            ];
            dotfiles.bootstrap.enable = true;
            namespace = "kube-system";
            resources.ciliumLoadBalancerIPPools.home.spec = {
              allowFirstLastIPs = "Yes";
              blocks = [
                {
                  start = "192.168.50.251";
                  stop = "192.168.50.254";
                }
              ];
            };
            helm.releases.cilium = {
              chart = charts.cilium.cilium;
              values = mkMerge [
                {
                  autoDirectNodeRoutes = true;
                  dashboards.enabled = true;
                  devices = ["br0" "eno1"];
                  envoy.rollOutPods = true;
                  hubble = {
                    metrics.dashboards.enabled = true;
                    relay.enabled = true;
                    relay.rollOutPods = true;
                    relay.prometheus.enabled = true;
                    ui.enabled = true;
                    ui.rollOutPods = true;
                  };
                  # TODO why doesn't this actually change the Pod CIDRs on CiliumNode?
                  # ipam.operator.clusterPoolIPv4PodCIDRList = ["10.42.0.0/16"];
                  # ipv4NativeRoutingCIDR = "10.42.0.0/16";
                  ipv4NativeRoutingCIDR = "10.0.0.0/8";
                  kubeProxyReplacement = true;
                  k8sServiceHost = "localhost";
                  k8sServicePort = 6444;
                  operator = {
                    dashboards.enabled = true;
                    prometheus.enabled = true;
                    replicas = 1;
                    rollOutPods = true;
                  };
                  prometheus.enabled = true;
                  rollOutCiliumPods = true;
                  routingMode = "native";
                }
                {
                  # Pinned images
                  envoy.image = pinImage images.cilium-envoy;
                  hubble.relay.image = pinImage images.cilium-hubble-relay;
                  hubble.ui.backend.image = pinImage images.cilium-hubble-ui-backend;
                  hubble.ui.frontend.image = pinImage images.cilium-hubble-ui-frontend;
                  image = pinImage images.cilium;
                  operator.image.override = with images.cilium-operator; "${imageName}:${finalImageTag}";
                }
              ];
            };
          };
        };
      })
    ];
  };
}
