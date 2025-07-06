{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.kube-state-metrics.enable = lib.mkEnableOption "kube-state-metrics";
    config = lib.mkIf config.services.kube-state-metrics.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.kube-state-metrics = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
          imageDigest = "sha256:db384bf43222b066c378e77027a675d4cd9911107adba46c2922b3a55e10d6fb";
          hash = "sha256-hbotlRY6h9pm15HEnGSAZ/F2wNt/aKpxi8hv2DJi28Y=";
          finalImageTag = "v2.15.0";
        };
      };
      nixidy = {lib, ...}: {
        applications.kube-state-metrics = {
          namespace = "monitoring";
          helm.releases.kube-state-metrics = {
            chart = lib.helm.downloadHelmChart {
              chart = "kube-state-metrics";
              version = "6.1.0";
              repo = "oci://ghcr.io/prometheus-community/charts";
              chartHash = "sha256-NXi8/TC11zmPNHPKYvcvOaMVdCmn2Y5krvnd7KyBTXE=";
            };
            values.fullnameOverride = "kube-state-metrics";
            values.image.tag = "v2.15.0";
            values.prometheus.monitor = {
              enabled = true;
              honorLabels = true;
            };
          };
        };
      };
    };
  };
}
