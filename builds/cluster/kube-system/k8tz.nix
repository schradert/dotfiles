{lib, ...}: {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://k8tz.github.io/k8tz"];
  # [ ] [k8tz](https://github.com/k8tz/k8tz)
  perSystem.canivete.kubenix.helm.k8tz = {
    namespace = "kube-system";
    chart = {
      repo = "https://k8tz.github.io/k8tz";
      chart = "k8tz";
      version = "0.16.2";
      sha256 = "sVdg7TG+6WB9+z+r2POJP9GrjIgTVgdj0omGAbqzMRU=";
    };
    values = {
      namespace = null;
      timezone = "America/Los_Angeles";
      cronJobTimeZone = true;
      affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = lib.toList {
        weight = 1;
        podAffinityTerm.labelSelector.matchLabels."app.kubernetes.io/name" = "k8tz";
        podAffinityTerm.topologyKey = "kubernetes.io/hostname";
      };
    };
  };
  # The health-test pod runs before the service is ready, so we force it to retry
  # perSystem.canivete.kubenix.clusters.prod.modules.k8tz-patch.kubernetes.api.resources.core.v1.Pod.k8tz-health-test.spec.restartPolicy = lib.mkForce "OnFailure";
}
