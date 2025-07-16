{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "excalidraw.${config.domain}";
    image = {
      imageName = "excalidraw/excalidraw";
      imageDigest = "sha256:525d72908ffed09807bad50321b94698d725ddc5945118dc3e0b4a494f9772a8";
      hash = "sha256-CWnyHqZbYsCeT0nDJEl+hk+/ocISDW75TC7CGXB30dI=";
      finalImageTag = "latest";
    };
  in {
    options.services.excalidraw.enable = mkEnableOption "excalidraw";
    config = mkIf services.excalidraw.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.excalidraw = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        applications.excalidraw = {
          namespace = "dotfiles";
          helm.releases.excalidraw = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.excalidraw.containers.excalidraw = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.excalidraw.ports.http.port = 80;
              }
              (mkIf services.cilium.enable {
                route.excalidraw = {
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
