{config, nix, ...}: with nix; let
  inherit (config.dotfiles) domain;
  namespace = "network";
  chart = {
    repo = "https://kubernetes.github.io/ingress-nginx";
    chart = "ingress-nginx";
    version = "4.11.2";
    sha256 = "dZZrlFQOEOC89r5Jn6fCeP8Oot98e1NhS+asnTmgvJg=";
  };
  values = {
    defaultBackend.enable = false;
    controller = {
      allowSnippetAnnotations = true;
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
      extraArgs.default-ssl-certificate = "security/${replaceStrings ["."] ["-"] domain}-tls";
      metrics.enabled = true;
      metrics.serviceMonitor = {
        enabled = true;
        namespace = "network";
        namespaceSelector.any = true;
      };
      replicaCount = 2;
      terminationGracePeriodSeconds = 120;
    };
  };
  release = {inherit namespace chart values;};
  admissionWebhook = type: {
    objectSelector.matchExpressions = toList {
      key = "ingress-class";
      operator = "In";
      values = [type];
    };
  };
  topologySpreadConstraint = type: toList {
    maxSkew = 1;
    topologyKey = "kubernetes.io/hostname";
    whenUnsatisfiable = "DoNotSchedule";
    labelSelector.matchLabels = {
      "app.kubernetes.io/name" = "ingress-nginx";
      "app.kubernetes.io/instance" = "nginx-${type}";
      "app.kubernetes.io/component" = "controller";
    };
  };
in {
  perSystem = {
    dotfiles.nix2container.nginx = {};
    dotfiles.helm.nginx-internal = recursiveUpdate release {
      values.fullnameOverride = "nginx-internal";
      values.controller = {
        service.annotations."external-dns.alpha.kubernetes.io/hostname" = "internal.${domain}";
        service.annotations."lbipam.cilium.io/ips" = "192.168.50.201";
        ingressClassResource.name = "internal";
        ingressClassResource.controllerValue = "k8s.io/internal";
        admissionWebhooks = admissionWebhook "internal";
        topologySpreadConstraints = topologySpreadConstraint "internal";
      };
    };
    dotfiles.helm.nginx-external = recursiveUpdate release {
      values.fullnameOverride = "nginx-external";
      values.controller = {
        service.annotations."external-dns.alpha.kubernetes.io/hostname" = "external.${domain}";
        service.annotations."lbipam.cilium.io/ips" = "192.168.50.202";
        ingressClassResource.name = "external";
        ingressClassResource.controllerValue = "k8s.io/external";
        admissionWebhooks = admissionWebhook "external";
        topologySpreadConstraints = topologySpreadConstraint "external";
      };
    };
  };
}
