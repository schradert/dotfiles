{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "registry.k8s.io/nfd/node-feature-discovery";
      imageDigest = "sha256:5ad4e3ac1afcbeb9d096241b0352614e5e77ee1bfe0f37c45a8d7b4329599d11";
      hash = "sha256-yfbSaO8g4o88Ac8aVZ5SPMlSBlF/RyCSBoyJJUUS00I=";
      finalImageTag = "v0.17.3";
    };
  in {
    options.services.node-feature-discovery.enable = lib.mkEnableOption "node-feature-discovery";
    config = lib.mkIf config.services.node-feature-discovery.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.node-feature-discovery = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        applications.node-feature-discovery = {
          namespace = "kube-system";
          helm.releases.node-feature-discovery = {
            chart = charts.kubernetes-sigs.node-feature-discovery;
            values.image = {
              repository = image.imageName;
              pullPolicy = "Never";
              tag = image.finalImageTag;
            };
            values.prometheus.enable = config.services.prometheus.enable;
            values.worker.config.core.sources = ["pci" "system" "usb"];
          };
        };
      };
    };
  };
}
