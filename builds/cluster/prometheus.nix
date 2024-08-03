{
  perSystem.canivete.kubenix.clusters.prod.modules.prometheus = {helm, ...}: let
    repo = "https://prometheus-community.github.io/helm-charts";
  in {
    kubernetes.resources.namespaces.prometheus = {};
    kubernetes.helm.releases = {
      prometheus-operator-crds = {
        namespace = "prometheus";
        chart = helm.fetch {
          inherit repo;
          chart = "prometheus-operator-crds";
          version = "13.0.2";
          sha256 = "";
        };
      };
      kube-prometheus-stack = {
        namespace = "prometheus";
        chart = helm.fetch {
          chart = "kube-prometheus-stack";
          version = "61.7.0";
          sha256 = "";
        };
      };
    };
  };
}
