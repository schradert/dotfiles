{
  perSystem.dotfiles.nix2container.seaweedfs = {};
  perSystem.dotfiles.helm = {
    seaweedfs.namespace = "storage";
    seaweedfs.chart = {
      repo = "https://seaweedfs.github.io/seaweedfs/helm";
      chart = "seaweedfs";
      version = "4.0.0";
      sha256 = "DwpXo3/TEaMXiPsn8Ga/L9hzrF3uxhkX2T2FyJmoqtI=";
    };
    seaweedfs.values.image = {
      registry = "ref+envsubst://SEAWEEDFS_IMAGE_REGISTRY";
      repository = "ref+envsubst://SEAWEEDFS_IMAGE_REPOSITORY";
    };
    seaweedfs-csi-driver.namespace = "storage";
    seaweedfs-csi-driver.chart = {
      repo = "https://seaweedfs.github.io/seaweedfs-csi-driver/helm";
      chart = "seaweedfs-csi-driver";
      version = "0.2.2";
      sha256 = "LbmbS7LWTbvn0tZMlWWyNeHZurCvZkl0r81Ywk0YXnE=";
    };
    seaweedfs-csi-driver.values.seaweedfsFiler = "seaweedfs-filer:8888";
  };
}
