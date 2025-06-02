{
  # TODO Intel Quick Sync Video
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) mkEnableOption mkIf toList;
    subdomain = "plex.${domain}";
    image = {
      imageName = "ghcr.io/onedr0p/plex";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.plex.enable = mkEnableOption "plex";
    config = mkIf config.services.plex.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.plex = pkgs.dockerTools.pullImage image;};
      kubenix.kubernetes.helm.releases.plex = {
        namespace = "media";
        values = {
          controllers.plex = {
            annotations."reloader.stakater.com/auto" = "true";
            pod.nodeSelector."kubernetes.io/hostname" = "octopus";
            containers.plex = {
              image.repository = image.imageName;
              image.tag = image.finalImageTag;
              probes.liveness.enabled = true;
              probes.readiness.enabled = true;
              probes.startup = {
                enabled = true;
                spec.failureThreshold = 30;
                spec.periodSeconds = 5;
              };
              resources.requests = {
                cpu = "100m";
                memory = "10Gi";
              };
              resources.limits.memory = "10Gi";
            };
          };
          service.plex = {
            controller = "plex";
            type = "LoadBalancer";
            annotations."lbipam.cilium.io/ips" = "192.168.50.203";
            ports.http.port = 32400;
          };
          ingress.plex = {
            annotations."external-dns.alpha.kubernetes.io/target" = "external.${domain}";
            annotations."nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS";
            className = "external";
            hosts = toList {
              host = subdomain;
              paths = toList {
                path = "/";
                service.identifier = "plex";
                service.port = "http";
              };
            };
          };
          persistence = {
            data.existingClaim = "plex-data";
            data.advancedMounts.plex.plex = [{path = "/config";}];
            config.existingClaim = "plex-config";
            config.advancedMounts.plex.plex = [{path = "/config";}];
            cache.existingClaim = "plex-cache";
            cache.advancedMounts.plex.plex = [{path = "/config/Library/Application Support/Plex Media Server/Cache";}];
            logs.type = "emptyDir";
            logs.advancedMounts.plex.plex = [{path = "/config/Library/Application Support/Plex Media Server/Logs";}];
            transcode.type = "emptyDir";
            transcode.advancedMounts.plex.plex = [{path = "/transcode";}];
          };
        };
      };
    };
  };
}
