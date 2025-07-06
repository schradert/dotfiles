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
      nixidy = {lib, ...}: let
        chart = lib.helm.downloadHelmChart {
          repo = "https://piraeus.io/helm-charts";
          chart = "snapshot-controller";
          version = "4.0.2";
          chartHash = "sha256-RONBeALvdliIfnCcPnwqBwSbk68bUWOIvoUj3K3EuaE=";
        };
      in {
        dotfiles.crds.snapshot-controller = {
          src = chart;
          prefix = "crds/";
          crds = [
            "groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses"
            "groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents"
            "groupsnapshot.storage.k8s.io_volumegroupsnapshots"
            "snapshot.storage.k8s.io_volumesnapshotclasses"
            "snapshot.storage.k8s.io_volumesnapshotcontents"
            "snapshot.storage.k8s.io_volumesnapshots"
          ];
        };
        applications.snapshot-controller = {
          namespace = "storage";
          helm.releases.snapshot-controller = {
            inherit chart;
            values.controller.serviceMonitor.create = services.prometheus.enable;
          };
        };
      };
    };
  };
}
