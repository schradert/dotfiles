{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mapAttrs mkEnableOption mkIf mkForce mkMerge;
    registryUrl = "quay.io";
    owner = "cilium";
    appVersion = "v1.17.6";
    imageTag = appVersion;
    cilium = image: "${owner}/${image}";
    images = {
      cilium-cilium = {
        inherit registryUrl imageTag;
        imageName = cilium "cilium";
        imageManifest = ./manifests/cilium.json;
      };
      cilium-cilium-envoy = {
        inherit registryUrl;
        imageName = cilium "cilium-envoy";
        imageTag = "v1.34.3-1753136543-8da82c827e7e5b2ad5f107f7f485073bcb7a797f";
        imageManifest = ./manifests/cilium-envoy.json;
      };
      cilium-hubble-relay = {
        inherit registryUrl imageTag;
        imageName = cilium "hubble-relay";
        imageManifest = ./manifests/cilium-hubble-relay.json;
      };
      cilium-hubble-ui-backend = {
        inherit registryUrl;
        imageName = cilium "hubble-ui-backend";
        imageTag = "v0.13.2";
        imageManifest = ./manifests/cilium-hubble-ui-backend.json;
      };
      cilium-hubble-ui-frontend = {
        inherit registryUrl;
        imageName = cilium "hubble-ui";
        imageTag = "v0.13.2";
        imageManifest = ./manifests/cilium-hubble-ui-frontend.json;
      };
      cilium-operator-generic = {
        inherit registryUrl imageTag;
        imageName = cilium "operator-generic";
        imageManifest = ./manifests/cilium-operator.json;
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
        devenv = {
          config,
          pkgs,
          ...
        }: let
          inherit
            ((config.lib.getInput {
                name = "nix2container";
                url = "github:nlewo/nix2container";
                attribute = "containers";
                follows = ["nixpkgs"];
              }).packages.${
                pkgs.stdenv.system
              }.nix2container)
            pullImageFromManifest
            ;
        in {
          packages = [pkgs.cilium-cli];
          containers = mapAttrs (_: args: {derivation = pullImageFromManifest args;}) images;
        };
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
                canivete.bootstrap.exclude = builtins.map (name: "monitoring.coreos.com/v1/ServiceMonitor/${name}") [
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
            canivete.bootstrap.enable = true;
            namespace = "kube-system";
            # FIXME why do I have to force override? "null and not null"
            resources.namespaces.cilium-secrets.metadata.annotations = lib.mkForce {"argocd.argoproj.io/sync-options" = "Prune=confirm";};
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
                    # Avoid Secrets in GitOps
                    tls.auto.method = "cronJob";
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
