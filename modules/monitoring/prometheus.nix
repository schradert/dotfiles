{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (builtins) concatStringsSep head mapAttrs tail;
    inherit (config) domain;
    inherit (lib) getExe mkEnableOption mkIf splitString toList;
    pinImage = image: let
      parts = splitString "/" image.imageName;
    in {
      registry = head parts;
      repository = concatStringsSep "/" (tail parts);
      tag = image.finalImageTag;
      pullPolicy = "Never";
    };
    appVersion = "v0.84.0";
    images = {
      prometheus = {
        imageName = "quay.io/prometheus/prometheus";
        imageDigest = "sha256:63805ebb8d2b3920190daf1cb14a60871b16fd38bed42b857a3182bc621f4996";
        hash = "sha256-AN+3pMNugZVfmqbU0typ+GnNDs/+eVSOZUg+Gh1Cuf8=";
        finalImageTag = "v3.5.0";
      };
      prometheus-operator = {
        imageName = "quay.io/prometheus-operator/prometheus-operator";
        imageDigest = "sha256:f128a6969e458a58cc51befebe98bf78a18060be0f7bf62ca91a271505eb7875";
        hash = "sha256-USePLknFULGGZ93XPSr7fBmsTbSEKPLSFkyC4gYtv3k=";
        finalImageTag = appVersion;
      };
      prometheus-admission-webhook = {
        imageName = "quay.io/prometheus-operator/admission-webhook";
        imageDigest = "sha256:72a1f42d7439864b171d91a1d6f0202bdd48913bff1d0f11e5cab47d04c74351";
        hash = "sha256-LsUUecnDDa49xGaZCRus8D6ghuumxV9JfNfTw/CmdRo=";
        finalImageTag = appVersion;
      };
      prometheus-config-reloader = {
        imageName = "quay.io/prometheus-operator/prometheus-config-reloader";
        imageDigest = "sha256:697a5fdc409d8fbec55cfa389b62bbde04e74aaa6b67485a0ab8bd4ee5ab4b5c";
        hash = "sha256-0Vh+FhYfELEsGQlpLomljMcxsCsN6+c9QiKyHPEbOIw=";
        finalImageTag = appVersion;
      };
      prometheus-certgen = {
        imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
        imageDigest = "sha256:c9f76a75fd00e975416ea1b73300efd413116de0de8570346ed90766c5b5cefb";
        hash = "sha256-t/DVrYCqwzixjtXkXFOtLCpRk4dHF43knpwCANz6wxc=";
        finalImageTag = "v1.6.0";
      };
    };
  in {
    options.services.prometheus.enable = mkEnableOption "prometheus";
    config = mkIf config.services.prometheus.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        dotfiles.crds.prometheus = let
          chart = charts.prometheus-community.kube-prometheus-stack;
          prefix = "charts/crds/crds";
        in {
          inherit prefix;
          install = true;
          # TODO how can I separate Prometheus CRDs into the different apps?
          # Alertmanager config has invalid YAML (lone = needs to be quoted)
          src = pkgs.patchOut chart "${getExe pkgs.gnused} --in-place \"s/- =$/- '='/\" $out/${prefix}/*.yaml";
        };
        applications.prometheus = {
          namespace = "monitoring";
          dotfiles.volsync.pvcs.prometheus = {
            title = "prometheus-prometheus-kube-prometheus-prometheus-db-prometheus-prometheus-kube-prometheus-prometheus-0";
            # TODO what happens with multiple deployments???
            # TODO resurrect this injection when StorageClass changes
            # path = ["prometheuses" "prometheus-kube-prometheus-prometheus" "spec" "storage" "volumeClaimTemplate"];
          };
          helm.releases.prometheus = {
            chart = charts.prometheus-community.kube-prometheus-stack;
            values = {
              crds.enabled = false;
              kubelet.enabled = true;
              kubeApiServer.enabled = true;
              prometheus = {
                prometheusSpec.image = pinImage images.prometheus;
                prometheusSpec.storageSpec.volumeClaimTemplate.spec = {
                  accessModes = ["ReadWriteOnce"];
                  resources.requests.storage = "10Gi";
                };
                route.main = {
                  enabled = true;
                  hostnames = ["prometheus.${domain}"];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              };
              prometheusOperator = {
                admissionWebhooks.deployment.enabled = true;
                admissionWebhooks.deployment.image = pinImage images.prometheus-admission-webhook;
                admissionWebhooks.patch.image = pinImage images.prometheus-certgen;
                image = pinImage images.prometheus-operator;
                prometheusConfigReloader.image = pinImage images.prometheus-config-reloader;
              };

              # Deployed separately
              alertmanager.enabled = false;
              kubeControllerManager.enabled = false;
              kubeEtcd.enabled = false;
              kubeProxy.enabled = false;
              kubeScheduler.enabled = false;
              kubeStateMetrics.enabled = false;
              nodeExporter.enabled = false;
              grafana.enabled = false;
              grafana.forceDeployDashboards = true;
            };
          };
        };
      };
    };
  };
}
