{pkgs, ...}: {
  imports = [./modules];
  namespaces.new = ["oauth2-proxy" "prometheus" "traefik" "keycloak"];
  repositories.helm.oauth2-proxy.spec.url = "https://oauth2-proxy.github.io/manifests";
  repositories.helm.traefik.spec.url = "https://traefik.github.io/charts";
  repositories.helm.prometheus.spec.url = "https://prometheus-community.github.io/helm-charts";
  repositories.helm.keycloak.spec = {
    type = "oci";
    url = "oci://registry-1.docker.io/bitnamicharts";
  };
  repositories.git.podinfo = {
    metadata.namespace = "flux-system";
    spec.url = "https://github.com/stefanprodan/podinfo";
    spec.ref.branch = "master";
  };
  releases.helm.oauth2-proxy = {
    spec.chart.spec.version = "6.19.1";
    spec.values = {
      config.existingSecret = "oauth2-proxy";
      # config.configFile = builtins.readFile ../../oauth2-proxy-config.py;
    };
  };
  releases.helm.traefik = {
    spec.chart.spec.version = "24.0.0";
    spec.values = {
      additionalArguments = [
        "--api.insecure"
        "--accesslog"
        "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      ];
      certResolvers.letsencrypt-staging-tls = {
        email = "tristan@t0rdos.me";
        tlsChallenge = true;
        storage = "letsencrypt-staging-tls.json";
        caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
      certResolvers.letsencrypt-production-tls = {
        email = "tristan@t0rdos.me";
        tlsChallenge = true;
        storage = "letsencrypt-production-tls.json";
        caServer = "https://acme-v02.api.letsencrypt.org/directory";
      };
      ingressRoute.dashboard.entryPoints = ["websecure"];
      ingressRoute.dashboard.matchRule = "Host(`proxy.tord0s.me`)";
      ingressRoute.dashboard.tls.certResolver = "letsencrypt-staging-tls";
    };
  };
  releases.helm.prometheus-operator-crds = {
    metadata.namespace = "prometheus";
    spec.chart.spec.version = "6.0.0";
  };
  releases.helm.kube-prometheus-stack = {
    metadata.namespace = "prometheus";
    spec.dependsOn = "prometheus-operator-crds";
    spec.chart.spec.version = "51.4.0";
    spec.values.crds.enabled = false;
  };
  releases.helm.keycloak.spec.chart.spec.version = "17.3.5";
  kustomizations.podinfo = {
    spec = {
      interval = "30m0s";
      timeout = "3m0s";
      retryInterval = "2m0s";
      wait = true;
      prune = true;
      targetNamespace = "default";
      path = "./kustomize";
      patches = [
        {
          patch = pkgs.toYAML {
            apiVersion = "autoscaling/v2";
            kind = "HorizontalPodAutoscaler";
            metadata.name = "podinfo";
            spec.minReplicas = 3;
          };
          target.name = "podinfo";
          target.kind = "HorizontalPodAutoscaler";
        }
      ];
    };
  };
}
