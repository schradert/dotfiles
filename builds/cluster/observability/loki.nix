{config, nix, ...}: with nix; let
  inherit (config.dotfiles) domain;
  bucketNames = {
    chunks = "loki-chunks";
    ruler = "loki-ruler";
  };
  component = {
    replicas = 2;
    extraArgs = ["-config.expand-env=true"];
    extraEnvFrom = [
      {secretRef.name = "loki-chunks";}
      {configMapRef.name = "loki-chunks";}
      {secretRef.name = "loki-ruler"; prefix = "RULER_";}
      {configMapRef.name = "loki-ruler"; prefix = "RULER_";}
    ];
  };
in {
  #[ ] [Loki](https://github.com/grafana/loki)
  # TODO s3 object storage?
  # TODO authn on ingress? or better to use gateway?
  # TODO manage deprecation and migration to grafana/meta-monitoring-chart
  # TODO why can't I do string templating with env vars
  perSystem.dotfiles.helm.loki = {
    namespace = "observability";
    chart = {
      repo = "https://grafana.github.io/helm-charts";
      chart = "loki";
      version = "6.12.0";
      sha256 = "YUtEIUiQWRzlttfOOgDk1xfTaiAZ12tIgpGr1QcMpro=";
    };
    values = rec {
      global.extraEnvFrom = [
        {secretRef.name = "loki-chunks";}
        {configMapRef.name = "loki-chunks";}
        {secretRef.name = "loki-ruler"; prefix = "RULER_";}
        {configMapRef.name = "loki-ruler"; prefix = "RULER_";}
      ];
      deploymentMode = "SimpleScalable";
      loki = {
        auth_enabled = false;
        analytics.reporting_enabled = false;
        commonConfig.replication_factor = 2;
        compactor.working_directory = "/var/loki/compactor/retention";
        compactor.delete_request_store = "s3";
        compactor.retention_enabled = true;
        ingester.chunk_encoding = "lz4-1M";
        # TODO limits config? query_scheduler?
        podAnnotations."secret.reloader.stakater.com/reload" = "loki";
        rulerConfig = {
          enable_alertmanager_v2 = true;
          alertmanager_url = "http://prometheus-kube-prometheus-alertmanager.observability.svc.cluster.local:9093";
          storage.type = "s3";
          storage.s3 = {
            s3forcepathstyle = true;
            bucketnames = "\${RULER_BUCKET_NAME}";
            endpoint = "http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80";
            access_key_id = "\${RULER_AWS_ACCESS_KEY_ID}";
            secret_access_key = "\${RULER_AWS_SECRET_ACCESS_KEY}";
            region = "\${RULER_BUCKET_REGION}";
          };
        };
        schemaConfig.configs = toList {
          from = "2024-04-01";
          store = "tsdb";
          object_store = "s3";
          schema = "v13";
          index.prefix = "loki_index_";
          index.period = "24h";
        };
        storage.type = "s3";
        storage.bucketNames = bucketNames // {admin = "loki-admin";};
        storage.s3 = {
          s3ForcePathStyle = true;
          endpoint = "http://rook-ceph-rgw-ceph-objectstore.storage.svc.cluster.local:80";
          accessKeyId = "\${AWS_ACCESS_KEY_ID}";
          secretAccessKey = "\${AWS_SECRET_ACCESS_KEY}";
          region = "\${BUCKET_REGION}";
        };
        tracing.enabled = true;
      };
      gateway.enabled = false;
      ingress = {
        enabled = true;
        ingressClassName = "internal";
        hosts = ["loki.${domain}"];
        annotations = {
          "external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
          "nginx.ingress.kubernetes.io/whitelist-source-range" = concatStringsSep "," ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"];
        };
      };
      read = component;
      write = component // {persistence.storageClass = "openebs-hostpath";};
      backend = component // {persistence.storageClass = "openebs-hostpath";};
      monitoring = {
        dashboards.enabled = true;
        dashboards.annotations.grafana_folder = "Loki";
        rules.enabled = true;
        serviceMonitor.enabled = true;
      };
      sidecar.rules.searchNamespace = "ALL";
      lokiCanary.enabled = false;
      test.enabled = false;
      chunksCache.enabled = false;
      resultsCache.enabled = false;
    };
    resources.objectbucketclaims = genAttrs (attrValues bucketNames) (name: {
      spec.bucketName = name;
      spec.storageClassName = "ceph-bucket";
    });
  };
  perSystem.dotfiles.helm.grafana.values.datasources."datasources.yaml" = {
    deleteDatasources = toList {name = "Loki"; orgId = 1;};
    datasources = toList {
      name = "Loki";
      type = "loki";
      uid = "loki";
      access = "proxy";
      url = "http://loki-headless.observability.svc.cluster.local:80";
      jsonData.maxLines = 250;
    };
  };
}
