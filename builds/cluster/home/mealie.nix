{
  perSystem.canivete.arion.modules.mealie.services.mealie = {
    service.ports = ["9000:9000"];
    nixos.configuration.services.mealie.enable = true;
    nixos.useSystemd = true;
  };
  perSystem.canivete.kubenix.clusters.prod.modules.mealie = {helm, ...}: {
    kubernetes.helm.releases.mealie = {
      chart = helm.fetch {
        repo = "https://bjw-s.github.io/helm-charts";
        chart = "app-template";
        version = "3.3.2";
        sha256 = "9Lx3jPGiLaE+joGy2GWxLzjWDu8wCa+4DrS9atf2zug=";
      };
    };
  };
}
