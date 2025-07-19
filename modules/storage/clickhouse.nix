{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf toList;
    images.clickhouse-operator = {
      imageName = "altinity/clickhouse-operator";
      imageDigest = "sha256:23cf85b707a9de542d27b54cf548688bfb040f84bec4f311cbfdeb3e01357239";
      hash = "sha256-6rPtoF5Jss4tt0r6wrusTfj6+FwaUcbwNdXsRlW2/ig=";
      finalImageTag = "0.25.3";
    };
    images.clickhouse-metrics-exporter = {
      imageName = "altinity/metrics-exporter";
      imageDigest = "sha256:ff8d20291a5708efaec892b7ff48637522009531647f112e09a82239783848c8";
      hash = "sha256-E3D2pZ2dYnPHlhPkCeHWFBe0HSgPk4IUdHhin9kw38c=";
      finalImageTag = "0.25.3";
    };
    images.clickhouse-server = {
      imageName = "altinity/clickhouse-server";
      imageDigest = "sha256:34d1c346e47643dbbe39fc5acb1453fa4339260d7f83ad6c51694794b1517d93";
      hash = "sha256-wKCp7YhukP/Bq5o0UmmQ/Y4pLTqo/5leyshXGfMyR5o=";
      finalImageTag = "24.8.14.10501.altinitystable";
    };
  in {
    options.services.clickhouse.enable = mkEnableOption "Clickhouse";
    config = mkIf services.clickhouse.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      opentofu.passwords.clickhouse.length = 21;
      opentofu.dotfiles.secrets.clickhouse.value = "\${ random_password.clickhouse.result }";
      nixidy = {lib, ...}: let
        chart = lib.helm.downloadHelmChart {
          chart = "clickhouse";
          version = "0.2.6";
          repo = "https://helm.altinity.com";
          chartHash = "sha256-iZ398zuhaBkH6h4Ne7LFjGEU1t538sMc/YBgX2q6jxw=";
        };
      in {
        dotfiles.crds.clickhouse = {
          install = true;
          prefix = "charts/altinity-clickhouse-operator/crds";
          src = chart;
        };
        applications.clickhouse = {
          namespace = "storage";
          dotfiles.volsync.pvcs = {
            clickhouse = "clickhouse-data-chi-clickhouse-clickhouse-0-0-0";
            clickhouse-logs = "clickhouse-logs-chi-clickhouse-clickhouse-0-0-0";
          };
          helm.releases.clickhouse = {
            inherit chart;
            values.operator = {
              dashboards.enabled = services.grafana.enable;
              metrics.image = with images.clickhouse-metrics-exporter; {
                pullPolicy = "Never";
                repository = imageName;
                tag = finalImageTag;
              };
              operator.image = with images.clickhouse-operator; {
                pullPolicy = "Never";
                repository = imageName;
                tag = finalImageTag;
              };
              serviceMonitor.enabled = services.prometheus.enable;
              # TODO is this even mounted anywhere or necessary?
              secret.create = false;
            };
            values.clickhouse = {
              defaultUser.hostIP = "10.0.0.0/24";
              clusterSecret.enabled = true;
              persistence.logs.enabled = true;
              image = with images.clickhouse-server; {
                repository = imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
              serviceAccount.create = true;
            };
          };
          resources = mkIf services.external-secrets.enable {
            secrets.clickhouse-credentials.stringData = mkForce {};
            externalSecrets.clickhouse-credentials.spec = {
              data = toList {
                secretKey = "password";
                remoteRef.key = "clickhouse";
                sourceRef.storeRef.name = "bitwarden";
                sourceRef.storeRef.kind = "ClusterSecretStore";
              };
              target.template.data = {
                user = "default";
                password = "{{ .password }}";
              };
            };
          };
        };
      };
    };
  };
}
