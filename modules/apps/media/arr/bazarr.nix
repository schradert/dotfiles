{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "bazarr.${config.domain}";
    image = {
      imageName = "ghcr.io/home-operations/bazarr";
      imageDigest = "sha256:dbc87e5ce9e199709188e152e82b3ff5d33e6521a1b3d61e465aa75b4b739e7f";
      hash = "sha256-15XkDowVoEDnU0LG4N3fkpFZOKR3mniP/hRqm2t6YHw=";
      finalImageTag = "1.5.2";
    };
  in {
    options.services.bazarr.enable = mkEnableOption "bazarr";
    config = mkIf services.bazarr.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.bazarr = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.bazarr.url = "https" + "://${hostname}";
        applications.bazarr = {
          namespace = "media";
          dotfiles.volsync.pvcs.bazarr.title = "bazarr";
          helm.releases.bazarr = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.bazarr.containers.bazarr = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.bazarr.ports.http.port = 6767;
                persistence.config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1G";
                };
                # TODO how should I actually store media?
                # persistence.media = {
                #   type = "nfs";
                #   server = "nfs.internal";
                #   path = "/mnt/...";
                #   globalMounts = toList {
                #     path = "/media";
                #     readOnly = true;
                #   };
                # };
                persistence.tmpfs = {
                  type = "emptyDir";
                  globalMounts = [
                    {
                      path = "/config/cache";
                      subPath = "log";
                    }
                    {
                      path = "/config/log";
                      subPath = "log";
                    }
                    {
                      path = "/tmp";
                      subPath = "tmp";
                    }
                  ];
                };
              }
              (mkIf services.cilium.enable {
                route.bazarr = {
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
