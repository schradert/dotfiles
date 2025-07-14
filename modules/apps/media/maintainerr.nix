{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "maintainerr.${config.domain}";
    image = {
      imageName = "ghcr.io/jorenn92/maintainerr";
      imageDigest = "sha256:f0ad693314830eade8df47df348bae50e1639002cf9158f54f6d149772fb0f53";
      hash = "sha256-8iUu2QTQ2mCNds04jl8YzYUCgGYVxfuJOs3AiMaUBzU=";
      finalImageTag = "2.18.2";
    };
  in {
    options.services.maintainerr.enable = mkEnableOption "maintainerr";
    config = mkIf services.maintainerr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.maintainerr = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.maintainerr.url = "https" + "://${hostname}";
        applications.maintainerr = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.maintainerr.title = "maintainerr";
          helm.releases.maintainerr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.maintainerr.containers.maintainerr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.maintainerr.ports.http.port = 80;
                persistence.config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                  globalMounts = [{path = "/opt/data";}];
                };
                persistence.tmpfs = {
                  type = "emptyDir";
                  globalMounts = toList {
                    path = "/tmp";
                    subPath = "tmp";
                  };
                };
              }
              (mkIf services.cilium.enable {
                route.maintainerr = {
                  hostnames = [hostname];
                  parentRefs = toList {
                    name = "internal";
                    namespace = "kube-system";
                    sectionName = "https";
                  };
                };
              })
            ];
          };
        };
      };
    };
  };
}
