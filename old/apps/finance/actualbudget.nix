{
  # TODO update for multiple user support https://github.com/actualbudget/actual/issues/524
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    inherit (config) domain;
    hostname  = "actual.${domain}";
    port = 5006;
    image = {
      imageName = "ghcr.io/actualbudget/actual-server";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.actualbudget.enable = mkEnableOption "actualbudget";
    config = mkIf config.services.actualbudget.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.actualbudget = pkgs.dockerTools.pullImage image;};
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
                service.actual.ports.http.port = port;
                persistence.data.existingClaim = "actual";
                persistence.data.globalMounts = [{path = "/data";}];
                configMaps.actual.data = {
                  ACTUAL_PORT = builtins.toString port;
                  ACTUAL_LOGIN_METHOD = "header";
                };
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
