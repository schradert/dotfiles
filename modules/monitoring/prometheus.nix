{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) getExe mkEnableOption mkIf toList;
    certgen-tag = "v1.5.2";
    admission-tag = "v0.83.0";
  in {
    options.services.prometheus.enable = mkEnableOption "prometheus";
    config = mkIf config.services.prometheus.enable {
      nixos = {pkgs, ...}: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        canivete.kubernetes.images = {
          prometheus-operator = pullImage {
            imageName = "quay.io/prometheus-operator/prometheus-operator";
            imageDigest = "sha256:5f6a204b252e901b97486ff409c74f48cdbb4cf83731355b08f1155febad6822";
            hash = "sha256-Eb2xUZuXmti3LClShjMHnht48LeftkH/NJFQN0qfT0Q=";
            finalImageTag = "v0.81.0";
          };
          prometheus = pullImage {
            imageName = "quay.io/prometheus/prometheus";
            imageDigest = "sha256:6927e0919a144aa7616fd0137d4816816d42f6b816de3af269ab065250859a62";
            hash = "sha256-k0C4Y1xNBPy+OA4OKINiyE+4gcHQf8YelJ8p7nwH/XI=";
            finalImageTag = "v3.2.1";
          };
          prometheus-admission-webhook = pullImage {
            imageName = "quay.io/prometheus-operator/admission-webhook";
            imageDigest = "sha256:b0d9c9e531e9d40e91d0789de1e4839d9218c18c5071b229408265caad3f39f5";
            hash = "sha256-7Xo/AsDDAfmwj89bPwvmDZqg+enBBvpkgd1OXXH205o=";
            finalImageTag = admission-tag;
          };
          prometheus-config-reloader = pullImage {
            imageName = "quay.io/prometheus-operator/prometheus-config-reloader";
            imageDigest = "sha256:959d47672fbff2776a04ec62b8afcec89e8c036af84dc5fade50019dab212746";
            hash = "sha256-M6icjqAoMG3v7GjO4pakn1QIj0gwA2m8CROIKJxzSG4=";
            finalImageTag = "v0.81.0";
          };
          prometheus-certgen = pullImage {
            imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
            imageDigest = "sha256:e8825994b7a2c7497375a9b945f386506ca6a3eda80b89b74ef2db743f66a5ea";
            hash = "sha256-JS2+CtDDTOD8TcXtfTdCUD9Bo6MfGAYkWfO7o/+uo+E=";
            finalImageTag = certgen-tag;
          };
        };
      };
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
              prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec = {
                accessModes = ["ReadWriteOnce"];
                resources.requests.storage = "10Gi";
              };
              prometheus.route.main = {
                enabled = true;
                hostnames = ["prometheus.${domain}"];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
              };
              prometheusOperator.admissionWebhooks = {
                deployment.enabled = true;
                deployment.image.tag = admission-tag;
                patch.image.tag = certgen-tag;
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
