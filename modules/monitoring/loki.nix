{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "grafana/loki";
      imageDigest = "sha256:d12ab5b1cd7ac58c1c0ea8cb43e0d151d1d5bee1cb897c7e7eaf225adae07928";
      hash = "sha256-UNmBIlcCwaJ9fK5U9GuLFqfdlZgiX/U6eoM87UkdwB8=";
      finalImageTag = "3.5.2";
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
              read.replicas = 0;
              singleBinary.replicas = 1;
              singleBinary.persistence.enabled = true;
              write.replicas = 0;

              loki = {
                commonConfig.replication_factor = 1;
                storage.type = "filesystem";
                # FIXME why specify buckets when using filesystem?
                storage.bucketNames.chunks = "loki-chunks";
                image.repository = image.imageName;
                image.tag = image.finalImageTag;
                image.pullPolicy = "Never";
                compactor = {
                  working_directory = "/var/loki/compactor/retention";
                  delete_request_store = "filesystem";
                  retention_enabled = true;
                };

                # Seems like I HAVE to define this: https://grafana.com/docs/loki/latest/operations/storage/schema/
                schemaConfig.configs = lib.toList {
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
  };
}
