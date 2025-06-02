{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) replaceStrings mkEnableOption mkIf recursiveUpdate;
  in {
    options.services.nginx.enable = mkEnableOption "nginx";
    config = mkIf services.nginx.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images = {
          nginx-certgen = pkgs.dockerTools.pullImage {
            imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
            imageDigest = "sha256:e8825994b7a2c7497375a9b945f386506ca6a3eda80b89b74ef2db743f66a5ea";
            hash = "sha256-JS2+CtDDTOD8TcXtfTdCUD9Bo6MfGAYkWfO7o/+uo+E=";
            finalImageTag = "v1.5.2";
          };
          nginx-controller = pkgs.dockerTools.pullImage {
            imageName = "registry.k8s.io/ingress-nginx/controller";
            imageDigest = "sha256:d2fbc4ec70d8aa2050dd91a91506e998765e86c96f32cffb56c503c9c34eed5b";
            hash = "sha256-l00oUCgD2+UBpbvmvBj5s5tNL60pGhJGyIAYT/gxgb8=";
            finalImageTag = "v1.12.1";
          };
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.helm.releases = let
          release = {inherit namespace chart values;};
          # TODO can I use a different namespace?
          # namespace = "network";
          namespace = "kube-system";
          chart = helm.fetch {
            repo = "https://kubernetes.github.io/ingress-nginx";
            chart = "ingress-nginx";
            version = "4.12.1";
            sha256 = "sha256-GEzgtcwJ+lZ9ymCDey54bD7BZkCpXoDcIQU0MjzAxcA=";
          };
          values = {
            controller = {
              # Expects digest label which dockerTools doesn't do
              admissionWebhooks.patch.image.digest = "";
              image.digest = "";
              config.force-ssl-redirect = "true";
              extraArgs.default-ssl-certificate = "security/${replaceStrings ["."] ["-"] domain}-tls";
            };

            # defaultBackend.enable = false;
            # controller = {
            #   allowSnippetAnnotations = true;
            #   config = {
            #     block-user-agents = replaceStrings ["\n"] [","] (fileContents ./robots.txt);
            #     client-body-buffer-size = "100M";
            #     client-body-timeout = 120;
            #     client-header-timeout = 120;
            #     enable-brotli = "true";
            #     enable-ocsp = "true";
            #     enable-real-ip = "true";
            #     hide-headers = "Server,X-Powered-By";
            #     hsts-max-age = 31449600;
            #     keep-alive = 120;
            #     keep-alive-requests = 10000;
            #     log-format-escape-json = "true";
            #     log-format-upstream = replaceStrings ["\n" " "] ["" ""] (fileContents ./logs.json);
            #     proxy-body-size = 0;
            #     proxy-buffer-size = "16k";
            #     ssl-protocols = "TLSv1.3 TLSv1.2";
            #     use-forwarded-headers = "true";
            #   };
            #   metrics.enabled = true;
            #   metrics.serviceMonitor = {
            #     enabled = true;
            #     namespace = "network";
            #     namespaceSelector.any = true;
            #   };
            #   replicaCount = 2;
            #   terminationGracePeriodSeconds = 120;
            # };
          };
          # admissionWebhook = type: {
          #   objectSelector.matchExpressions = toList {
          #     key = "ingress-class";
          #     operator = "In";
          #     values = [type];
          #   };
          # };
          # topologySpreadConstraint = type:
          #   toList {
          #     maxSkew = 1;
          #     topologyKey = "kubernetes.io/hostname";
          #     whenUnsatisfiable = "DoNotSchedule";
          #     labelSelector.matchLabels = {
          #       "app.kubernetes.io/name" = "ingress-nginx";
          #       "app.kubernetes.io/instance" = "nginx-${type}";
          #       "app.kubernetes.io/component" = "controller";
          #     };
          #   };
        in {
          nginx-internal = recursiveUpdate release {
            values.fullnameOverride = "nginx-internal";
            values.controller = {
              service.annotations."external-dns.alpha.kubernetes.io/hostname" = "internal.${domain}";
              # FIXME choose Tailscale IP
              # TODO should this be a tailscale IP if I switch to VPN?
              # service.annotations."lbipam.cilium.io/ips" = "192.168.50.201";
              ingressClassResource.name = "internal";
              ingressClassResource.default = true;
              ingressClassResource.controllerValue = "k8s.io/internal";
              # admissionWebhooks = admissionWebhook "internal";
              # topologySpreadConstraints = topologySpreadConstraint "internal";
            };
          };
          nginx-external = recursiveUpdate release {
            values.fullnameOverride = "nginx-external";
            values.controller = {
              service.annotations."external-dns.alpha.kubernetes.io/hostname" = "external.${domain}";
              # FIXME choose Tailscale IP
              # service.annotations."lbipam.cilium.io/ips" = "192.168.50.202";
              ingressClassResource.name = "external";
              ingressClassResource.controllerValue = "k8s.io/external";
              # admissionWebhooks = admissionWebhook "external";
              # topologySpreadConstraints = topologySpreadConstraint "external";
            };
          };
        };
      };
    };
  };
}
