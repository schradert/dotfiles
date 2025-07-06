let
  repo = "https://kubernetes-sigs.github.io/descheduler";
in {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [repo];
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.descheduler.enable = lib.mkEnableOption "descheduler";
    config = lib.mkIf config.services.descheduler.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.descheduler = pkgs.dockerTools.pullImage {
          imageName = "registry.k8s.io/descheduler/descheduler";
          imageDigest = "sha256:df9583a5b0e30e9984a517019316d72674fbfd6ad6065c95284333f7ff1963d4";
          hash = "sha256-R1A5NbO3XBim0N+3DKL00XLgXG85GMY7D3PlzrtgLo8=";
          finalImageTag = "v0.32.2";
        };
      };
      nixidy = {lib, ...}: {
        applications.descheduler = {
          namespace = "cicd";
          helm.releases.descheduler = {
            chart = lib.helm.downloadHelmChart {
              inherit repo;
              chart = "descheduler";
              version = "0.32.2";
              chartHash = "sha256-y/i6hIV/YsNRF0U5HPunIsEGoA7i2613vtjKeLuYlk8=";
            };
            values = {
              replicas = 1;
              kind = "Deployment";
              deschedulerPolicyAPIVersion = "descheduler/v1alpha2";
              deschedulerPolicy.profiles = lib.toList {
                name = "Default";
                pluginConfig = [
                  {name = "RemovePodsViolatingInterPodAntiAffinity";}
                  {name = "RemovePodsViolatingNodeTaints";}
                  {
                    name = "RemovePodsViolatingNodeAffinity";
                    args.nodeAffinityType = ["requiredDuringSchedulingIgnoredDuringExecution"];
                  }
                  {
                    name = "RemovePodsViolatingTopologySpreadConstraint";
                    args.constraints = ["DoNotSchedule" "ScheduleAnyway"];
                  }
                  {
                    name = "DefaultEvictor";
                    args = {
                      evictFailedBarePods = true;
                      evictLocalStoragePods = true;
                      evictSystemCriticalPods = true;
                      nodeFit = true;
                    };
                  }
                ];
                plugins.balance.enabled = ["RemovePodsViolatingTopologySpreadConstraint"];
                plugins.deschedule.enabled = [
                  "RemovePodsViolatingInterPodAntiAffinity"
                  "RemovePodsViolatingNodeAffinity"
                  "RemovePodsViolatingNodeTaints"
                ];
              };
              service.enabled = true;
              serviceMonitor.enabled = config.services.prometheus.enable;
              leaderElection.enabled = true;
            };
          };
        };
      };
    };
  };
}
