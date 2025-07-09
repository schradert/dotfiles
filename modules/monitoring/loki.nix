{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "grafana/loki";
      imageDigest = "sha256:a74594532eec4cc313401beedc4dd2708c43674c032084b1aeb87c14a5be1745";
      hash = "sha256-tgP1TCoykKpKCTyn/S4FLkd+dYAYYJlKX0DZTy+Y1RU=";
      finalImageTag = "3.5.1";
    };
  in {
    options.services.loki.enable = lib.mkEnableOption "loki";
    config = lib.mkIf config.services.loki.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.loki = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        applications.loki = {
          namespace = "monitoring";
          helm.releases.loki = {
            chart = charts.grafana.loki;
            values = {
              deploymentMode = "SingleBinary";
              backend.replicas = 0;
              gateway.replicas = 0;
              loki.commonConfig.replication_factor = 1;
              read.replicas = 0;
              singleBinary.replicas = 1;
              write.replicas = 0;

              singleBinary.persistence.enabled = true;
              loki.storage.type = "filesystem";
              loki.compactor = {
                working_directory = "/var/loki/compactor/retention";
                delete_request_store = "filesystem";
                retention_enabled = true;
              };

              # Seems like I HAVE to define this: https://grafana.com/docs/loki/latest/operations/storage/schema/
              loki.schemaConfig.configs = lib.toList {
                from = "2024-04-01";
                object_store = "filesystem";
                store = "tsdb";
                schema = "v13";
                index.prefix = "index_";
                index.period = "24h";
              };
            };
          };
        };
      };
    };
  };
}
