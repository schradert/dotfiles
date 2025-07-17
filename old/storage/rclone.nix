{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkIf mkMerge toList;
    hostname = "rclone.${config.domain}";
    port = 5572;
    image = {
      imageName = "rclone/rclone";
      imageDigest = "sha256:7f83ec1efe4a2359395f483c92db51b0f2698a4c17fcff1e5a4d2eacebce5d22";
      hash = "";
      finalImageTag = "sha-521d6b8";
    };
  in {
    options.services.rclone.enable = mkEnableOption "Rclone";
    config = mkIf services.rclone.enable {
      home-manager = {
        config,
        pkgs,
        ...
      }: {
        # TODO package https://github.com/darkhz/rclone-tui
        home.packages = mkIf config.dotfiles.profiles.client.workstation.enable (with pkgs; [croc rclone termscp]);
      };
      nixos = {pkgs, ...}: {canivete.kubernetes.images.rclone = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        dotfiles.gatus.endpoints.rclone.url = "https" + "://${hostname}";
        applications.rclone = {
          namespace = "dotfiles";
          helm.releases.rclone = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                controllers.rclone.containers.rclone = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  args = ["rcd"];
                  envFrom = [{configMapRef.name = "rclone";}];
                  probes.liveness.enabled = true;
                  probes.readiness.enabled = true;
                  probes.startup.enabled = true;
                };
                service.rclone.ports.http.port = port;
                configMaps.rclone.data = {
                  RCLONE_RC = "true";
                  RCLONE_RC_ADDR = "0.0.0.0:${toString port}";
                  RCLONE_RC_WEB_GUI = "true";
                  RCLONE_RC_WEB_GUI_NO_OPEN_BROWSER = "true";
                };
              }
              (mkIf services.reloader.enable {
                controllers.rclone.annotations."reloader.stakater.com/auto" = "true";
              })
              (mkIf services.cilium.enable {
                route.rclone = {
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
