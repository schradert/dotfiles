{config, ...}: let
  inherit (config.dotfiles) domain;
in {
  # TODO figure out prometheus in nix
  # TODO make sure to get all the endpoints like sonarr, radarr, lidarr
  # TODO alertmanager
  # [ ] [prometheus-node-exporter](https://github.com/prometheus/node_exporter)
  # [ ] [prometheus-smartctl-exporter](https://github.com/prometheus-community/smartctl_exporter)
  # [ ] [prometheus-snmp-exporter](https://github.com/prometheus/snmp_exporter)
  perSystem.canivete.kubenix.clusters.prod.modules.prometheus = {helm, nix, ...}: {
    kubernetes.helm.releases.prometheus = {
      chart = helm.fetch {
        repo = "https://prometheus-community.github.io/helm-charts";
        chart = "kube-prometheus-stack";
        version = "61.7.0";
        sha256 = "U5BvJnBbgGe1KFS2nFd8Bc3v+sqjR1CWQDCzDlq6ebk=";
      };
    };
  };
}
