{
  # TODO figure out hardware acceleration and nodeAffinity
  # TODO find a good helm chart or roll with app-template
  # NOTE https://gitlab.com/bunkbed/backbone/-/blob/migrate-to-on-prem/src/cluster/jellyfin.nix?ref_type=heads
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    inherit (lib) mkEnableOption mkIf toList;
    port = 8096;
    subdomain = "jellyfin.${domain}";
    probe.enabled = true;
    probe.custom = true;
    probe.spec = {
      httpGet.path = "/health";
      httpGet.port = port;
      initialDelaySeconds = 0;
      periodSeconds = 10;
      timeoutSeconds = 1;
      failureThreshold = 3;
    };
  in {
    options.services.jellyfin.enable = mkEnableOption "Jellyfin";
    config = mkIf config.services.jellyfin.enable {
      home-manager = {
        config,
        pkgs,
        ...
      }: {
        home.packages = mkIf (config.dotfiles.workstation.enable && pkgs.stdenv.hostPlatform.isLinux) [pkgs.jftui];
      };
      kubenix = {helm, ...}: {
        dotfiles.gatus.endpoints.jellyfin.url = "https://${subdomain}";
        kubernetes.helm.releases.jellyfin = {
          namespace = "media";
          values = {
            configMaps.jellyfin.data = {
              DOTNET_SYSTEM_IO_DISABLEFILELOCKING = "true";
              JELLYFIN_FFmpeg__probesize = "50000000";
              JELLYFIN_FFmpeg__analyzeduration = "50000000";
              JELLYFIN_PublishedServerUrl = subdomain;
            };
            controllers.jellyfin = {
              annotations."reloader.stakater.com/auto" = "true";
              # TODO selector for Intel Quick Sync Video
              pod.nodeSelector."kubernetes.io/hostname" = "octopus";
              containers.jellyfin = {
                image.repository = "ghcr.io/onedr0p/jellyfin";
                image.tag = "10.8.11@sha256:926e2a9f6677a0c7b12feba29f36c954154869318d6a52df72f72ff9c74cf494";
                envFrom = [{configMapRef.name = "jellyfin";}];
                probes.liveness = probe;
                probes.readiness = probe;
                probes.startup.enabled = false;
                resources.requests.cpu = "100m";
                resources.requests.memory = "512Mi";
                resources.limits.memory = "4Gi";
              };
            };
            service.jellyfin.controller = "jellyfin";
            service.jellyfin.ports.http.port = port;
            ingress.jellyfin = {
              className = "external";
              hosts = toList {
                host = subdomain;
                paths = toList {
                  path = "/";
                  service.identifier = "jellyfin";
                  service.port = "http";
                };
              };
            };
            persistence = {
              transcode.type = "emptyDir";
              transcode.advancedMounts.jellyfin.jellyfin = [{path = "/transcode";}];
              config.existingClaim = "jellyfin";
              config.advancedMounts.jellyfin.jellyfin = [{path = "/config";}];
            };
          };
        };
      };
    };
  };
}
