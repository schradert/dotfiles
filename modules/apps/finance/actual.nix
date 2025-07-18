{
  # TODO update for multiple user support https://github.com/actualbudget/actual/issues/524
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    inherit (config) services;
    hostname = "actual.${config.domain}";
    image = {
      imageName = "ghcr.io/actualbudget/actual-server";
      imageDigest = "sha256:b6bb759f31d1c2c82a37d04f9d8930359ae8e3b3faa8eaa5338a0a2328702908";
      hash = "sha256-ynjUL7aml5DGuZWHWb2dc77QlTkjPsoz0ilwTBJBXm4=";
      finalImageTag = "25.7.1";
    };
  in {
    options.services.actual.enable = mkEnableOption "actual";
    config = mkIf config.services.actual.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.actual = pkgs.dockerTools.pullImage image;};
      opentofu = {
        dotfiles.secrets.actual.value = "\${ random_password.actual.result }";
        passwords.actual = {
          length = 21;
          special = false;
        };
      };
      nixidy = {charts, ...}: {
        applications.actual = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs.actual = "actual";
          helm.releases.actual = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.actual.containers.actual = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  envFrom = toList {configMapRef.name = "actual";};
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.actual.ports.http.port = 5006;
                persistence.data = {
                  type = "persistentVolumeClaim";
                  size = "1Gi";
                  accessMode = "ReadWriteOnce";
                };
                # FIXME add proxy HTTP headers to authenticate safely
                configMaps.actual.data.ACTUAL_LOGIN_METHOD = "header";
              }
              (mkIf services.reloader.enable {
                controllers.actual.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.actual = {
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
