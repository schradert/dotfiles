{config, nix, ...}: with nix; let
  inherit (config.dotfiles) domain;
in {
  perSystem = {
    dotfiles.nix2container.nginx = {};
    dotfiles.helm.nginx-external = {
      namespace = "network";
      chart = {
        repo = "https://kubernetes.github.io/ingress-nginx";
        chart = "ingress-nginx";
        version = "4.11.2";
        sha256 = "dZZrlFQOEOC89r5Jn6fCeP8Oot98e1NhS+asnTmgvJg=";
      };
      values = {
        fullnameOverride = "nginx-external";
        defaultBackend.enable = false;
        controller = {
          config = {
            # NOTE https://github.com/superseriousbusiness/gotosocial/blob/main/internal/web/robots.go
            block-user-agents = replaceStrings ["\n"] [","] (fileContents ./robots.txt);
            client-body-buffer-size = "100M";
            client-body-timeout = 120;
            client-header-timeout = 120;
            enable-brotli = "true";
            enable-ocsp = "true";
            enable-real-ip = "true";
            force-ssl-redirect = "true";
            hide-headers = "Server,X-Powered-By";
            hsts-max-age = 31449600;
            keep-alive = 120;
            keep-alive-requests = 10000;
            log-format-escape-json = "true";
            log-format-upstream = replaceStrings ["\n" " "] ["" ""] (fileContents ./logs.json);
            proxy-body-size = 0;
            proxy-buffer-size = "16k";
            ssl-protocols = "TLSv1.3 TLSv1.2";
            use-forwarded-headers = "true";
          };
          service.annotations."external-dns.alpha.kubernetes.io/hostname" = "external.${domain}";
          replicaCount = 2;
          ingressClassResource.name = "external";
          ingressClassResource.default = false;
          ingressClassResource.controllerValue = "k8s.io/external";
          admissionWebhooks.objectSelector.matchExpressions = toList {
            key = "ingress-class";
            operator = "In";
            values = ["external"];
          };
          metrics.enabled = true;
          metrics.serviceMonitor = {
            enabled = true;
            namespace = "network";
            namespaceSelector.any = true;
          };
          extraArgs.default-ssl-certificate = "security/${replaceStrings ["."] ["-"] domain}-tls";
          allowSnippetAnnotations = true;
          enableAnnotationValidations = true;
          topologySpreadConstraints = toList {
            maxSkew = 1;
            topologyKey = "kubernetes.io/hostname";
            whenUnsatisfiable = "DoNotSchedule";
            labelSelector.matchLabels = {
              "app.kubernetes.io/name" = "ingress-nginx";
              "app.kubernetes.io/instance" = "nginx-internal";
              "app.kubernetes.io/component" = "controller";
            };
          };
        };
      };
    };
  };
}
