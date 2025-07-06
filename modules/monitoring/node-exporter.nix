{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.node-exporter.enable = lib.mkEnableOption "node-exporter";
    config = lib.mkIf config.services.node-exporter.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.node-exporter = pkgs.dockerTools.pullImage {
          imageName = "quay.io/prometheus/node-exporter";
          imageDigest = "sha256:d00a542e409ee618a4edc67da14dd48c5da66726bbd5537ab2af9c1dfc442c8a";
          hash = "sha256-ERdH5bx6U8vljQXiNTHFC4Xq+7SQmldZxmnj/7kJOIE=";
          finalImageTag = "v1.9.1";
        };
      };
      nixidy = {lib, ...}: {
        applications.node-exporter = {
          namespace = "monitoring";
          helm.releases.node-exporter = {
            chart = lib.helm.downloadHelmChart {
              chart = "prometheus-node-exporter";
              version = "4.47.1";
              repo = "oci://ghcr.io/prometheus-community/charts";
              chartHash = "sha256-evsJ1VEd/oNsGqv/ZJ/2Yh+Kzmr+dzxa5l/mUIdG6w4=";
            };
            values = {
              fullnameOverride = "node-exporter";
              hostNetwork = false;
              prometheus.monitor.enabled = true;
              # TODO do I need to relabel anything?
            };
          };
        };
      };
    };
  };
}
