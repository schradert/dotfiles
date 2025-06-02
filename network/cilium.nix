{
  perSystem = {pkgs, ...}: {
    canivete.devShells.shells.default.packages = [pkgs.cilium-cli];
  };
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkForce toList pipe hasSuffix;
  in {
    options.services.cilium.enable = mkEnableOption "Cilium CNI";
    config = mkIf config.services.cilium.enable {
      nixos = {
        config,
        pkgs,
        ...
      }: {
        options.dotfiles.cilium.enable = mkEnableOption "Cilium requirements" // {default = true;};
        config = mkIf config.dotfiles.cilium.enable {
          boot.blacklistedKernelModules = ["netfilter"];
          boot.kernelModules = ["cls_bpf" "sch_ingress" "crypto_user" "iptable_raw" "xt_socket"];
          canivete.kubernetes.images = {
            cilium-operator = pkgs.dockerTools.pullImage {
              imageName = "quay.io/cilium/operator-generic";
              imageDigest = "sha256:81f2d7198366e8dec2903a3a8361e4c68d47d19c68a0d42f0b7b6e3f0523f249";
              hash = "sha256-uPsMcW3bFGw0/J1HFSxrJhVKe22zqe1aG17tYxKvTK4=";
              finalImageTag = "v1.17.2";
            };
            cilium = pkgs.dockerTools.pullImage {
              imageName = "quay.io/cilium/cilium";
              imageDigest = "sha256:3c4c9932b5d8368619cb922a497ff2ebc8def5f41c18e410bcc84025fcd385b1";
              hash = "sha256-8Xxin5zQNBiBVLMYBG7ACDEiSBGbwcs4o4rLW2YKKXs=";
              finalImageTag = "v1.17.2";
            };
          };
          # TODO build https://github.com/hengyoush/kyanos
          environment.systemPackages = [pkgs.bpftop];
          networking.firewall.enable = mkForce false;
        };
      };
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
            rev = "v1.17.2";
            hash = "sha256-VVdKGJKCM8Kq4fLeONyv+mbNbl6FRUAfCtmmUg6Wc00=";
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
            {
              start = "178.156.159.148";
              stop = "178.156.159.148";
            }
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
            version = "1.17.2";
            sha256 = "sha256-l+9fEAb2wb9xAx/HCW/pXW5+MfzbgnSpWk7UOTkpK24=";
          };
          overrides = toList {
            metadata.annotations."kapp.k14s.io/change-group.cilium" = "cilium";
            metadata.annotations."kapp.k14s.io/change-rule.cilium" = "upsert before upserting not-cilium";
          };
          values = {
            image.useDigest = false;
            operator.image.useDigest = false;

            endpointRoutes.enabled = true;
            bpf.masquerade = true;
            bpf.tproxy = true;

            # Proxy
            # FIXME add physical NICs
            devices = ["tailscale0" "eth0"];
            kubeProxyReplacement = true;
            kubeProxyReplacementHealthzBindAddr = "0.0.0.0:10256";
            k8sServiceHost = "k8s.${config.domain}";
            k8sServicePort = 6443;

            # TODO expand nodes and add hubble monitoring
            operator.replicas = 1;
            envoy.enabled = false;
            hubble.enabled = false;
            hubble.ui.enabled = false;

            # TODO add additional configuration
            # hubble = {
            #   metrics.enabled = ["dns:query;ignoreAAAA" "drop" "tcp" "flow" "port-distribution" "icmp" "http"];
            #   metrics.serviceMonitor.enabled = true;
            #   metrics.dashboards.enabled = true;
            #   relay = {
            #     enabled = true;
            #     rollOutPods = true;
            #     prometheus.enabled = true;
            #     prometheus.serviceMonitor.enabled = true;
            #   };
            #   ui.enabled = true;
            #   ui.rollOutPods = true;
            #   ui.ingress = {
            #     enabled = true;
            #     className = "external";
            #     hosts = ["hubble.${domain}"];
            #     annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
            #     annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth?allowed_emails=me@trdos.me";
            #     annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
            #   };
            # };
            # operator.prometheus.serviceMonitor.enabled = true;
            # operator.dashboards.enabled = true;
            # prometheus.enabled = true;
            # prometheus.serviceMonitor.enabled = true;
            # prometheus.serviceMonitor.trustCRDsExist = true;
            # dashboards.enabled = true;
          };
        };
      };
    };
  };
}
