{
  perSystem.canivete.kubenix.clusters.prod.modules.forgejo = {helm, ...}: {
    kubernetes.helm.releases.forgejo.chart = helm.fetch {
      chartUrl = "oci://code.forgejo.org/forgejo-helm/forgejo";
      chart = "forgejo";
      version = "7.0.1";
      sha256 = "53TnACzIxvukPltumfqk8Cpofur5+8OaTQCPfGhasKs=";
    };
  };
}
