{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://k8tz.github.io/k8tz"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkForce mkIf toList;
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.k8tz.enable = mkEnableOption "k8tz";
    config = mkIf config.services.k8tz.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.k8tz = pkgs.dockerTools.pullImage image;};
      kubenix = {helm, ...}: {
        # The health-test pod runs before the service is ready, so we force it to retry
        kubernetes.api.resources.core.v1.Pod.k8tz-health-test.spec.restartPolicy = mkForce "OnFailure";
        kubernetes.helm.releases.k8tz = {
          namespace = "kube-system";
          chart = helm.fetch {
            repo = "https://k8tz.github.io/k8tz";
            chart = "k8tz";
            version = "0.16.2";
            sha256 = "sVdg7TG+6WB9+z+r2POJP9GrjIgTVgdj0omGAbqzMRU=";
          };
          values = {
            namespace = null;
            timezone = "America/Los_Angeles";
            cronJobTimeZone = true;
            affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = toList {
              weight = 1;
              podAffinityTerm.labelSelector.matchLabels."app.kubernetes.io/name" = "k8tz";
              podAffinityTerm.topologyKey = "kubernetes.io/hostname";
            };
          };
        };
      };
    };
  };
}
