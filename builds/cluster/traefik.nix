{
  perSystem.canivete.kubenix.clusters.prod.modules.traefik = {helm, ...}: {
    kubernetes.helm.releases.traefik.chart = helm.fetch {
      repo = "https://traefik.github.io/charts";
      chart = "traefik";
      version = "28.3.0";
      sha256 = "wRo7HRQpYF8Om6EwcOd7Krc12uJgElYgrY/xN1j0UNk=";
    };
  };
}
