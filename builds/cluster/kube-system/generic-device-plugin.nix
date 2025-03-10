{lib, ...}: {
  perSystem.canivete.kubenix.helm.generic-device-plugin = {
    namespace = "kube-system";
    values.defaultPodOptions.priorityClassName = "system-node-critical";
    values.controllers.generic-device-plugin = {
      type = "daemonset";
      strategy = "RollingUpdate";
      annotations."reloader.stakater.com/auto" = "true";
      containers.generic-device-plugin = {
        image.repository = "ghcr.io/squat/generic-device-plugin";
        image.tag = "36bfc606bba2064de6ede0ff2764cbb52edff70d@sha256:ba6f0b4cf6c858d6ad29ba4d32e4da11638abbc7d96436bf04f582a97b2b8821";
        args = ["--log-level" "info" "--config" "/config/config.yaml"];
        resources.requests.cpu = "10m";
        resources.limits.memory = "64Mi";
      };
    };
    values.persistence = {
      config.type = "configMap";
      config.name = "generic-device-plugin-configmap";
      config.globalMounts = lib.toList {
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
    resources.configMaps.generic-device-plugin-configmap.data."config.yaml" = builtins.toJSON {
      devices = lib.toList {
        name = "tun";
        groups = lib.toList {
          count = 1000;
          paths = [{path = "/dev/net/tun";}];
        };
      };
    };
  };
}
