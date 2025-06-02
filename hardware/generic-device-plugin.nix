{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    image = {
      imageName = "ghcr.io/squat/generic-device-plugin";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.generic-device-plugin.enable = mkEnableOption "generic-device-plugin";
    config = mkIf config.services.generic-device-plugin.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.generic-device-plugin = pkgs.dockerTools.pullImage image;};
      kubenix.kubernetes.helm.releases.generic-device-plugin = {
        namespace = "kube-system";
        values = {
          defaultPodOptions.priorityClassName = "system-node-critical";
          controllers.generic-device-plugin = {
            type = "daemonset";
            strategy = "RollingUpdate";
            annotations."reloader.stakater.com/auto" = "true";
            containers.generic-device-plugin = {
              image.repository = image.imageName;
              image.tag = image.finalImageTag;
              args = ["--log-level" "info" "--config" "/config/config.yaml"];
              resources.requests.cpu = "10m";
              resources.limits.memory = "64Mi";
            };
          };
          persistence = {
            config.type = "configMap";
            config.name = "generic-device-plugin";
            config.globalMounts = toList {
              path = "/config/config.yaml";
              subPath = "config.yaml";
              readOnly = true;
            };
            dev.type = "hostPath";
            dev.hostPath = "/dev";
            dev.globalMounts = [{readOnly = true;}];
            sys.type = "hostPath";
            sys.hostPath = "/sys";
            sys.globalMounts = [{readOnly = true;}];
            plugins.type = "hostPath";
            plugins.hostPath = "/var/lib/kubelet/device-plugins";
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
}
