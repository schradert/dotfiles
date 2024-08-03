{
  perSystem.canivete.kubenix.clusters.prod.modules.seaweedfs = {helm, ...}: {
    kubernetes.helm.releases.seaweedfs = {
      chart = helm.fetch {
        repo = "https://seaweedfs.github.io/seaweedfs/helm";
        chart = "seaweedfs";
        version = "4.0.0";
        sha256 = "sjO8q4CDhx7Gw3KFqDxIIrZ4lxBzpMu/oC+huH89Iuk=";
      };
      # TODO is this still necessary for it to work on bare metal??
      # values = let
      #   root = "/var/lib/seaweedfs";
      # in {
      #   master.data.hostPathPrefix = "${root}/ssd";
      #   master.logs.hostPathPrefix = "${root}/storage";
      #   volume.data.hostPathPrefix = "${root}/storage";
      #   volume.idx.hostPathPrefix = "${root}/ssd";
      #   volume.logs.hostPathPrefix = "${root}/storage";
      #   volume.dir = "${root}/data";
      #   filer.data.hostPathPrefix = "${root}/storage";
      #   filer.logs.hostPathPrefix = "${root}/storage";
      # };
    };
  };
}
