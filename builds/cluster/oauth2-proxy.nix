{
  perSystem.canivete.kubenix.clusters.prod.modules.oauth2-proxy = {helm, ...}: {
    kubernetes.helm.releases.oauth2-proxy.chart = helm.fetch {
      repo = "https://oauth2-proxy.github.io/manifests";
      chart = "oauth2-proxy";
      version = "7.7.8";
      sha256 = "Cz+TVaM2GBDklRRWMrrRkX3sjywQEz44mlQRhDgLhx4=";
    };
  };
}
