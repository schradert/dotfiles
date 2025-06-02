{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "ghcr.io/buroa/qbtools";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
    container = module:
      lib.mkMerge [
        {
          image.repository = image.imageName;
          image.tag = image.finalImageTag;
          args = ["--server" "qbittorrent.media.svc.cluster.local" "--port" "8080"];
          resources.requests.cpu = "25m";
          resources.requests.memory = "128Mi";
          resources.limits.memory = "256Mi";
        }
        module
      ];
    pruneArgs = ["prune" "--exclude-category" "manual" "--exclude-category"];
    cronjob = {
      schedule = "@hourly";
      concurrencyPolicy = "Forbid";
      successfulJobsHistory = 0;
      failedJobsHistory = 1;
    };
  in {
    options.services.qbtools.enable = lib.mkEnableOption "qbtools";
    config = lib.mkIf config.services.qbtools.enable {
      kubenix.kubernetes.helm.releases.qbtools = {
        namespace = "media";
        values.controllers = {
          prune = {
            type = "cronjob";
            inherit cronjob;
            pod.restartPolicy = "OnFailure";
            initContainers.tagging = container {args = ["tagging" "--added-on" "--expired" "--last-activity" "--sites" "--unregistered"];};
            containers.expired = container {args = pruneArgs ++ ["expired"];};
            containers.unregistered = container {args = pruneArgs ++ ["added:24h" "--include-tag" "unregistered"];};
          };
          orphaned = {
            type = "cronjob";
            cronjob = cronjob // {schedule = "@daily";};
            pod.restartPolicy = "OnFailure";
            containers.orphaned = container {args = ["orphaned" "--exclude-pattern" "*/manual/*"];};
          };
          reannounce.containers.reannounce = container {args = ["reannounce"];};
        };
        values.persistence.media = {
          existingClaim = "qbittorrent-media";
          advancedMounts.orphaned.orphaned = [{path = "/downloads";}];
        };
      };
    };
  };
}
