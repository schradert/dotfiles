{nix, ...}: with nix; {
  # [ ] [descheduler](https://github.com/kubernetes-sigs/descheduler)
  perSystem.dotfiles.helm.descheduler = {
    namespace = "kube-system";
    chart = {
      repo = "https://kubernetes-sigs.github.io/descheduler";
      chart = "descheduler";
      version = "0.30.1";
      sha256 = "rTaMuo+AAtBS6rMOhvtrXDEqYtNhoFAipO34RRK+Qj8=";
    };
    values = {
      replicas = 1;
      kind = "Deployment";
      deschedulerPolicyAPIVersion = "descheduler/v1alpha2";
      deschedulerPolicy.profiles = toList {
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
      serviceMonitor.enabled = true;
      leaderElection.enabled = true;
    };
  };
}
