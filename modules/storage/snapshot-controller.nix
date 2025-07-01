{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
  in {
    options.services.snapshot-controller.enable = lib.mkEnableOption "snapshot-controller";
    config = lib.mkIf services.snapshot-controller.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.snapshot-controller = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/sig-storage/snapshot-controller";
          imageDigest = "sha256:472fa35a89dadb5a715454fad576ec11aa6f2e8378fc09ae26473d139b77c437";
          hash = "sha256-UwzqhW6N/Pp2nLooiWBnukg4mXiDUK2aH/5+SygqamA=";
          finalImageTag = "v8.2.1";
        };
      };
      kubenix = {
        canivete,
        helm,
        ...
      }: let
        chart = helm.fetch {
          repo = "https://piraeus.io/helm-charts";
          chart = "snapshot-controller";
          version = "4.0.2";
          sha256 = "sha256-RONBeALvdliIfnCcPnwqBwSbk68bUWOIvoUj3K3EuaE=";
        };
      in {
        kubernetes.imports = canivete.filesets.files (name: _: lib.hasSuffix ".yaml" name) "${chart}/crds";
        kubernetes.helm.releases.snapshot-controller = {
          namespace = "storage";
          inherit chart;
          values.controller.serviceMonitor.create = services.prometheus.enable;
        };
      };
    };
  };
}
