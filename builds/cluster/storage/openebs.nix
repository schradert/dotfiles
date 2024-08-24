{
  perSystem.dotfiles.helm.openebs = {
    namespace = "storage";
    chart = {
      repo = "https://openebs.github.io/openebs";
      chart = "openebs";
      version = "4.1.0";
      sha256 = "kCC6Uw9Nlbcuz6ZaPZ9qL1mr8/Um06txKZ3Lm6UoWxg=";
    };
    values = {
      zfs-localpv.enabled = false;
      lvm-localpv.enabled = false;
      mayastor.enabled = false;
      engines.local.lvm.enabled = false;
      engines.local.zfs.enabled = false;
      engines.replicated.mayastor.enabled = false;
      openebs-crds.csi.volumeSnapshots = {
        enabled = false;
        keep = false;
      };
    };
  };
}
