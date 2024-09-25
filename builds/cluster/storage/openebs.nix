{nix, ...}: with nix; {
  canivete.deploy.nixos.modules.openebs = {config, ...}: {boot.kernelModules = mkIf config.dotfiles.kubernetes.enable ["dm_thin_pool"];};
  perSystem.dotfiles.helm.openebs = {
    namespace = "storage";
    chart = {
      repo = "https://openebs.github.io/openebs";
      chart = "openebs";
      version = "4.1.0";
      sha256 = "kCC6Uw9Nlbcuz6ZaPZ9qL1mr8/Um06txKZ3Lm6UoWxg=";
    };
    values = {
      localpv-provisioner.hostpathClass.basePath = "/var/lib/openebs/local";
      lvm-localpv.crds.lvmLocalPv.keep = false;
      # No need for ZFS or Mayastor
      engines.local.zfs.enabled = false;
      zfs-localpv.enabled = false;
      engines.replicated.mayastor.enabled = false;
      mayastor.enabled = false;
      # Volume snapshots handled elsewhere
      lvm-localpv.csi.volumeSnapshots.enabled = false;
      openebs-crds.csi.volumeSnapshots.enabled = false;
    };
    resources.storageClasses.openebs-lvm = {
      allowVolumeExpansion = true;
      parameters.storage = "lvm";
      parameters.thinProvision = "yes";
      parameters.volgroup = "k8s";
      provisioner = "local.csi.openebs.io";
      volumeBindingMode = "WaitForFirstConsumer";
    };
  };
}
