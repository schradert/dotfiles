{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = [
    "https://seaweedfs.github.io/seaweedfs/helm"
    "https://seaweedfs.github.io/seaweedfs-csi-driver/helm"
  ];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    image = {
      imageName = "";
      imageDigest = "";
      hash = "";
      finalImageTag = "";
    };
  in {
    options.services.seaweedfs.enable = lib.mkEnableOption "seaweedfs";
    config = lib.mkIf config.services.seaweedfs.enable {
      kubenix = {helm, ...}: {
        kubernetes.helm.releases = {
          seaweedfs.namespace = "storage";
          seaweedfs.chart = helm.fetch {
            repo = "https://seaweedfs.github.io/seaweedfs/helm";
            chart = "seaweedfs";
            version = "4.0.0";
            sha256 = "DwpXo3/TEaMXiPsn8Ga/L9hzrF3uxhkX2T2FyJmoqtI=";
          };
          seaweedfs.values.image = {
            registry = "";
            repository = "";
          };
          seaweedfs-csi-driver.namespace = "storage";
          seaweedfs-csi-driver.chart = helm.fetch {
            repo = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm";
            chart = "seaweedfs-csi-driver";
            version = "0.2.2";
            sha256 = "LbmbS7LWTbvn0tZMlWWyNeHZurCvZkl0r81Ywk0YXnE=";
          };
          seaweedfs-csi-driver.values.seaweedfsFiler = "seaweedfs-filer:8888";
        };
      };
    };
  };
}
