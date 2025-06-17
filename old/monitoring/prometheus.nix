{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) hasSuffix mkEnableOption mkIf pipe;
    version = "70.3.0";
    certgen-tag = "v1.5.2";
    admission-tag = "main";
    subdomain = "grafana.${domain}";
  in {
    options.services.prometheus.enable = mkEnableOption "prometheus";
    config = mkIf config.services.prometheus.enable {
      nixos = {pkgs, ...}: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        canivete.kubernetes.images = {
          alertmanager = pullImage {
            imageName = "quay.io/prometheus/alertmanager";
            imageDigest = "sha256:27c475db5fb156cab31d5c18a4251ac7ed567746a2483ff264516437a39b15ba";
            hash = "sha256-8ZuCk3GSdCgcWGkOm1lvVeCVywCmW3yFy2F4lkGczZM=";
            finalImageTag = "v0.28.1";
          };
          bats = pullImage {
            imageName = "docker.io/bats/bats";
            imageDigest = "sha256:f9e5272f8ccd9a21554e461c596b08553d052af78e509b8dffbd80ba89a34164";
            hash = "sha256-7lwKAAaviV6ooSFlA6N+6iKJw7gu3mEE33PX7qU38mM=";
            finalImageTag = "v1.4.1";
          };
          sidecar = pullImage {
            imageName = "quay.io/kiwigrid/k8s-sidecar";
            imageDigest = "sha256:9a326271c439b6f9e174f3b48ed132bbff71c00592c7dbd072ccdc334445bde2";
            hash = "sha256-WUsC82lkF5FZXiCBp8/sb870FNmQba9qSCRpqf8nz40=";
            finalImageTag = "1.30.0";
          };
          kube-state-metrics = pullImage {
            imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
            imageDigest = "sha256:db384bf43222b066c378e77027a675d4cd9911107adba46c2922b3a55e10d6fb";
            hash = "sha256-hbotlRY6h9pm15HEnGSAZ/F2wNt/aKpxi8hv2DJi28Y=";
            finalImageTag = "v2.15.0";
          };
          grafana = pullImage {
            imageName = "docker.io/grafana/grafana";
            imageDigest = "sha256:8b37a2f028f164ce7b9889e1765b9d6ee23fec80f871d156fbf436d6198d32b7";
            hash = "sha256-BnUST0SwBnrCE57qiS7agvtx9u+n9+RIdre1CWarFK8=";
            finalImageTag = "11.5.2";
          };
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
            imageDigest = "sha256:d7f8ab9af48c41696e421dafc3ddc0550117aae65d7bb3e576ad1f1dbff8ec36";
            hash = "sha256-In9GVoPqPUphoeqEElAALDAiL6Ya4LzTc5oy1Py3vcg=";
            finalImageTag = admission-tag;
          };
          prometheus-config-reloader = pullImage {
            imageName = "quay.io/prometheus-operator/prometheus-config-reloader";
            imageDigest = "sha256:959d47672fbff2776a04ec62b8afcec89e8c036af84dc5fade50019dab212746";
            hash = "sha256-M6icjqAoMG3v7GjO4pakn1QIj0gwA2m8CROIKJxzSG4=";
            finalImageTag = "v0.81.0";
          };
          node-exporter = pullImage {
            imageName = "quay.io/prometheus/node-exporter";
            imageDigest = "sha256:c99d7ee4d12a38661788f60d9eca493f08584e2e544bbd3b3fca64749f86b848";
            hash = "sha256-euz7RwAD50b6w+5D2qd3ssl0E9DZTbQkpaHVN/nHwNQ=";
            finalImageTag = "v1.9.0";
          };
          prometheus-certgen = pullImage {
            imageName = "registry.k8s.io/ingress-nginx/kube-webhook-certgen";
            imageDigest = "sha256:e8825994b7a2c7497375a9b945f386506ca6a3eda80b89b74ef2db743f66a5ea";
            hash = "sha256-JS2+CtDDTOD8TcXtfTdCUD9Bo6MfGAYkWfO7o/+uo+E=";
            finalImageTag = certgen-tag;
          };
        };
      };
      opentofu.passwords.grafana-admin.length = 21;
      kubenix = {
        canivete,
        helm,
        pkgs,
        ...
      }: {
        canivete.ifd.crds = {
          alertmanagers = "monitoring.coreos.com/v1/Alertmanager";
          prometheuses = "monitoring.coreos.com/v1/Prometheus";
          prometheusrules = "monitoring.coreos.com/v1/PrometheusRule";
          servicemonitors = "monitoring.coreos.com/v1/ServiceMonitor";
        };
        dotfiles.gatus.endpoints.grafana.url = "https://${subdomain}";
        kubernetes.imports =
          pipe {
            owner = "prometheus-community";
            repo = "helm-charts";
            rev = "kube-prometheus-stack-${version}";
            hash = "sha256-wwBqYfNlcITp0BrkDiCKVfiKMWivyJJ72RpHE+sKfVY=";
          } [
            pkgs.fetchFromGitHub
            (source: source + "/charts/kube-prometheus-stack/charts/crds/crds")
            (canivete.filesets.files (name: _: hasSuffix ".yaml" name))
          ];
        kubernetes.helm.releases.prometheus = {
          namespace = "monitoring";
          chart = helm.fetch {
            repo = "https://prometheus-community.github.io/helm-charts";
            chart = "kube-prometheus-stack";
            inherit version;
            sha256 = "sha256-ltn7BO6Se0LiI/3YWjQlJbIwklrI0q5/TSs525YN4bA=";
          };
          dotfiles.volsync.pvcs = {
            grafana = {
              title = "prometheus-grafana";
              uid = 472;
              gid = 472;
            };
            prometheus = {
              title = "prometheus-prometheus-kube-prometheus-prometheus-db-prometheus-prometheus-kube-prometheus-prometheus-0";
              # TODO what happens with multiple deployments???
              # TODO resurrect this injection when StorageClass changes
              # path = ["prometheuses" "prometheus-kube-prometheus-prometheus" "spec" "storage" "volumeClaimTemplate"];
            };
          };
          # NOTE /var/lib/grafana contents are frequently only owned by grafana
          extraResources.replicationsources.volsync--prometheus--grafana-src.spec.restic.moverSecurityContext.runAsUser = 472;
          values = {
            # TODO kubeProxy? how can I get this to work with Cilium equivalent?
            crds.enabled = false;
            # Prevent kapp injecting its own label into service selectors for statefulsets managed by prometheus-operator
            alertmanager.service.annotations."kapp.k14s.io/disable-default-label-scoping-rules" = "";
            prometheus.service.annotations."kapp.k14s.io/disable-default-label-scoping-rules" = "";
            prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec = {
              accessModes = ["ReadWriteOnce"];
              resources.requests.storage = "10Gi";
            };
            prometheusOperator.admissionWebhooks = {
              deployment.enabled = true;
              deployment.image.tag = admission-tag;
              patch.image.tag = certgen-tag;
            };
            grafana = {
              adminPassword = canivete.vals.sops.default "passwords/grafana-admin";
              ingress = {
                enabled = true;
                hosts = [subdomain];
                ingressClassName = "nginx";
                annotations."external-dns.alpha.kubernetes.io/target" = "nginx.${domain}";
                annotations."nginx.ingress.kubernetes.io/auth-url" = "https://oauth2-proxy.${domain}/oauth2/auth";
                annotations."nginx.ingress.kubernetes.io/auth-signin" = "https://oauth2-proxy.${domain}/oauth2/start?rd=$scheme://$host$request_uri";
              };
              persistence.enabled = true;
              # Managed by kubelet-csr-approver currently
              initChownData.image.tag = "latest";
            };

            # TODO should I use this config?
            # cleanPrometheusOperatorObjectNames = true;
            # alertmanager.ingress = {
            #   enabled = true;
            #   annotations."external-dns.alpha.kubernetes.io/target" = "internal.${domain}";
            #   ingressClassName = "internal";
            #   hosts = ["alertmanager.${domain}"];
            #   pathType = "Prefix";
            # };
            # alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec = {
            #   storageClassName = "openebs-hostpath";
            #   resources.requests.storage = "1Gi";
            # };
            # kubeApiServer.serviceMonitor.selector.k8s-app = "kube-apiserver";
            # kubeScheduler.service.selector.k8s-app = "kube-scheduler";
            # kubeControllerManager.service.selector.k8s-app = "kube-controller-manager";
            # kubeEtcd = kubeControllerManager;
            # kubeProxy.enabled = false;
            # prometheus.ingress = alertmanager.ingress // {hosts = ["alertmanager.${domain}"];};
            # prometheus.prometheusSpec = {
            #   ruleSelectorNilUsesHelmValues = false;
            #   serviceMonitorSelectorNilUsesHelmValues = false;
            #   podMonitorSelectorNilUsesHelmValues = false;
            #   probeSelectorNilUsesHelmValues = false;
            #   scrapeConfigSelectorNilUsesHelmValues = false;
            #   enableAdminAPI = true;
            #   walCompression = true;
            #   scrapeInterval = "1m"; # Must match interval in Grafana Helm chart
            #   enableFeatures = ["auto-gomemlimit" "auto-gomaxprocs" "memory-snapshot-on-shutdown" "new-service-discovery-manager"];
            #   replicas = 1;
            #   retention = "14d";
            #   retentionSize = "50GB";
            #   resources.requests.cpu = "100m";
            #   resources.limits.memory = "1500Mi";
            # };
            # kube-state-metrics.prometheus.monitor.enabled = true;
            # grafana.enabled = false;
            # grafana.forceDeployDashboards = true;
            # grafana.sidecar.dashboards.annotations.grafana_folder = "kubernetes";
          };
        };

        # Overrides
        kubernetes.api.resources = {
          core.v1.Pod.prometheus-grafana-test.metadata.annotations."kapp.k14s.io/change-rule.prometheus-grafana" = "upsert after upserting prometheus-grafana";
          apps.v1.Deployment.prometheus-grafana.metadata.annotations."kapp.k14s.io/change-group.prometheus-grafana" = "prometheus-grafana";
          # Kubernetes API server modifies these in place automatically
          "apiextensions.k8s.io".v1.CustomResourceDefinition = let
            strategy.spec.conversion.strategy = "None";
          in {
            "prometheusagents.monitoring.coreos.com" = strategy;
            "prometheuses.monitoring.coreos.com" = strategy;
            "alertmanagers.monitoring.coreos.com" = strategy;
            "alertmanagerconfigs.monitoring.coreos.com" = strategy;
            "scrapeconfigs.monitoring.coreos.com" = strategy;
            "thanosrulers.monitoring.coreos.com" = strategy;
          };
        };
      };
    };
  };
}
