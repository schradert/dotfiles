{lib, ...}: let
  inherit (lib) mkMerge;
  container = {
    image.repository = "ghcr.io/buroa/qbtools";
    image.tag = "v0.16.10";
    args = ["--server" "qbittorrent.media.svc.cluster.local" "--port" "8080"];
    resources.requests.cpu = "25m";
    resources.requests.memory = "128Mi";
    resources.limits.memory = "256Mi";
  };
  pruneArgs = ["prune" "--exclude-category" "manual" "--exclude-category"];
  cronjob = {
    schedule = "@hourly";
    concurrencyPolicy = "Forbid";
    successfulJobsHistory = 0;
    failedJobsHistory = 1;
  };
in {
  perSystem.dotfiles.helm.qbtools = {
    namespace = "media";
    values.controllers = {
      prune = {
        type = "cronjob";
        inherit cronjob;
        pod.restartPolicy = "OnFailure";
        initContainers.tagging = mkMerge [container {args = ["tagging" "--added-on" "--expired" "--last-activity" "--sites" "--unregistered"];}];
        containers.expired = mkMerge [container {args = pruneArgs ++ ["expired"];}];
        containers.unregistered = mkMerge [container {args = pruneArgs ++ ["added:24h" "--include-tag" "unregistered"];}];
      };
      orphaned = {
        type = "cronjob";
        cronjob = cronjob // {schedule = "@daily";};
        pod.restartPolicy = "OnFailure";
        containers.orphaned = mkMerge [container {args = ["orphaned" "--exclude-pattern" "*/manual/*"];}];
      };
      reannounce.containers.reannounce = mkMerge [container {args = ["reannounce"];}];
    };
    values.persistence.media = {
      existingClaim = "qbittorrent-media";
      advancedMounts.orphaned.orphaned = [{path = "/downloads";}];
    };
  };
}
