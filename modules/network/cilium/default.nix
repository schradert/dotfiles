{
  perSystem = {pkgs, ...}: {
    canivete.devShells.shells.default.packages = [pkgs.cilium-cli];
  };
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mapAttrs mkEnableOption mkIf mkForce mkMerge pipe hasSuffix;
    images = {
      cilium = {
        imageName = "quay.io/cilium/cilium";
        imageDigest = "sha256:baf8541723ee0b72d6c489c741c81a6fdc5228940d66cb76ef5ea2ce3c639ea6";
        hash = "sha256-KdIHQGk2fqCOM35/WkMSA/AqBbrbji6rIoml0VBO4Ds=";
        finalImageTag = "v1.17.5";
      };
      cilium-envoy = {
        imageName = "quay.io/cilium/cilium-envoy";
        imageDigest = "sha256:9f69e290a7ea3d4edf9192acd81694089af048ae0d8a67fb63bd62dc1d72203e";
        hash = "sha256-4hWULE6TYYxN/AvAlb8ritWfZ7YKmJLC4Ed8WUsD8hg=";
        finalImageTag = "v1.32.6-1749271279-0864395884b263913eac200ee2048fd985f8e626";
      };
      cilium-hubble-relay = {
        imageName = "quay.io/cilium/hubble-relay";
        imageDigest = "sha256:fbb8a6afa8718200fca9381ad274ed695792dbadd2417b0e99c36210ae4964ff";
        hash = "sha256-KZxrU6X3o5mG7dogbhz49WRDa1srLQAwOPmqrLM5ONo=";
        finalImageTag = "v1.17.5";
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
        imageDigest = "sha256:f954c97eeb1b47ed67d08cc8fb4108fb829f869373cbb3e698a7f8ef1085b09e";
        hash = "sha256-dDP8xBSqHiW/4Wxc2YlGOkM81zlfIbx2YCsS0vo3lvE=";
        finalImageTag = "v1.17.5";
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
          kubernetes.resources.ciliumloadbalancerippools.home = {
            metadata.annotations."kapp.k14s.io/change-group.cilium" = "cilium";
            spec.allowFirstLastIPs = "Yes";
            spec.blocks = [
              {
                start = "192.168.50.251";
                stop = "192.168.50.254";
              }
            ];
          };
          kubernetes.helm.releases.cilium = {
            namespace = "kube-system";
            chart = helm.fetch {
              repo = "https://helm.cilium.io";
              chart = "cilium";
              version = "1.17.5";
              sha256 = "sha256-94xCDaau6blpHx+GmlCmR4QmNfV2b27lMM9hYuDd0do=";
            };
            values = mkMerge [
              {
                autoDirectNodeRoutes = true;
                dashboards.enabled = true;
                devices = ["br0" "eno1"];
                envoy.rollOutPods = true;
                # envoy.prometheus.serviceMonitor.enabled = true;
                hubble = {
                  # metrics.serviceMonitor.enabled = true;
                  metrics.dashboards.enabled = true;
                  relay.enabled = true;
                  relay.rollOutPods = true;
                  relay.prometheus.enabled = true;
                  # relay.prometheus.serviceMonitor.enabled = true;
                  ui.enabled = true;
                  ui.rollOutPods = true;
                };
                # TODO why doesn't this actually change the Pod CIDRs on CiliumNode?
                # ipam.operator.clusterPoolIPv4PodCIDRList = ["10.42.0.0/16"];
                # ipv4NativeRoutingCIDR = "10.42.0.0/16";
                ipv4NativeRoutingCIDR = "10.0.0.0/8";
                kubeProxyReplacement = true;
                k8sServiceHost = "192.168.50.58";
                k8sServicePort = 6443;
                operator = {
                  dashboards.enabled = true;
                  prometheus.enabled = true;
                  # prometheus.serviceMonitor.enabled = true;
                  replicas = 1;
                  rollOutPods = true;
                };
                prometheus.enabled = true;
                # prometheus.serviceMonitor.enabled = true;
                prometheus.serviceMonitor.trustCRDsExist = true;
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
      })
    ];
  };
}
