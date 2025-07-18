{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    image = {
      imageName = "ghcr.io/squat/generic-device-plugin";
      imageDigest = "sha256:ba6f0b4cf6c858d6ad29ba4d32e4da11638abbc7d96436bf04f582a97b2b8821";
      hash = "sha256-Wyxgy5giKRdf1L6PVDTaiki+zWjhNS9oJeQ8lWK95pE=";
      finalImageTag = "36bfc606bba2064de6ede0ff2764cbb52edff70d";
    };
  in {
    options.services.generic-device-plugin.enable = mkEnableOption "generic-device-plugin";
    config = mkIf config.services.generic-device-plugin.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.generic-device-plugin = pkgs.dockerTools.pullImage image;};
      nixidy = {charts, ...}: {
        applications.generic-device-plugin = {
          namespace = "kube-system";
          helm.releases.generic-device-plugin = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              defaultPodOptions.priorityClassName = "system-node-critical";
              controllers.generic-device-plugin = {
                type = "daemonset";
                strategy = "RollingUpdate";
                annotations = mkIf config.services.reloader.enable {"reloader.stakater.com/auto" = "true";};
                containers.generic-device-plugin = {
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  args = ["--config" "/config/config.yaml"];
                };
              };
              persistence = {
                config = {
                  type = "configMap";
                  name = "generic-device-plugin";
                  globalMounts = toList {
                    path = "/config/config.yaml";
                    subPath = "config.yaml";
                    readOnly = true;
                  };
                };
                dev = {
                  type = "hostPath";
                  hostPath = "/dev";
                  globalMounts = [{readOnly = true;}];
                };
                sys = {
                  type = "hostPath";
                  hostPath = "/sys";
                  globalMounts = [{readOnly = true;}];
                };
                var-lib-kubelet-device-plugins = {
                  type = "hostPath";
                  hostPath = "/var/lib/kubelet/device-plugins";
                };
              };
              configMaps.generic-device-plugin.data."config.yaml" = builtins.toJSON {
                devices = toList {
                  name = "tun";
                  groups = toList {
                    count = 1000;
                    paths = [{path = "/dev/net/tun";}];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
