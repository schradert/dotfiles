{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.openebs.enable = lib.mkEnableOption "openebs";
    config = lib.mkIf config.services.openebs.enable {
      nixos = {
        config,
        pkgs,
        ...
      }: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        boot.kernelModules = lib.mkIf config.canivete.kubernetes.enable ["dm_thin_pool"];
        canivete.kubernetes.images = {
          openebs = pullImage {
            imageName = "openebs/provisioner-localpv";
            imageDigest = "sha256:23f8e4cae8c7e3aefc28d95338a355cde7a943b96005b5b62a7f58491413c1ed";
            hash = "sha256-cvbT/9rMWVk5bi2S+Hsu/MaQkZEBZiCKfqeolpJCsi8=";
            finalImageTag = "4.2.0";
          };
          kubectl = pullImage {
            imageName = "docker.io/bitnami/kubectl";
            imageDigest = "sha256:7a8d6955f40da47707896368ec4e7f9029ca643986af4ebcf4cbeb7798f0f896";
            hash = "sha256-5Ceo2lhcgNxtEPzw1Yd1T0cr2q7y1XJsRBQdHIIylkw=";
            finalImageTag = "1.25.15";
          };
          linux-utils = pullImage {
            imageName = "openebs/linux-utils";
            imageDigest = "sha256:f085850f69fdb278416d353a1bc1174613251ca9c471f5acd0e627eeb43e5d9e";
            hash = "sha256-fMfVkZaVm4Z5NyR61970RvY5u+3ocqnYjqWEN+wubUM=";
            finalImageTag = "4.1.0";
          };
        };
      };
      nixidy = {lib, ...}: {
        applications.openebs = {
          namespace = "storage";
          helm.releases.openebs = {
            chart = lib.helm.downloadHelmChart {
              chart = "openebs";
              version = "4.2.0";
              repo = "https://openebs.github.io/openebs";
              chartHash = "sha256-1exl4ZnLDpUHyFOjRZ+6LjP6SYIQ6IJeG88D7rNzWHY=";
            };
            values = {
              # NOTE just hostpath for now
              openebs-crds.csi.volumeSnapshots.enabled = false;
              localpv-provisioner = {
                hostpathClass.isDefaultClass = true;
                hostpathClass.basePath = "/var/lib/openebs/local";
              };
              zfs-localpv.crds.zfsLocalPv.enabled = false;
              lvm-localpv.crds.lvmLocalPv.enabled = false;
              mayastor.csi.node.initContainers.enabled = false;
              engines.local.lvm.enabled = false;
              engines.local.zfs.enabled = false;
              engines.replicated.mayastor.enabled = false;
            };
            # TODO enable ZFS
            # TODO enable LVM
            # extraResources.storageClasses.openebs-lvm = {
            #   allowVolumeExpansion = true;
            #   parameters.storage = "lvm";
            #   parameters.thinProvision = "yes";
            #   parameters.volgroup = "k8s";
            #   provisioner = "local.csi.openebs.io";
            #   volumeBindingMode = "WaitForFirstConsumer";
            # };
          };
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.resources.kappconfig.kapp.changeRuleBindings = lib.toList {
          rules = ["upsert after upserting chart.canivete.app/snapshot-controller"];
          resourceMatchers = lib.toList {hasAnnotationMatcher.keys = ["chart.canivete.app/openebs"];};
        };
        kubernetes.helm.releases.openebs = {
          namespace = "storage";
          chart = helm.fetch {
            repo = "https://openebs.github.io/openebs";
            chart = "openebs";
            version = "4.2.0";
            sha256 = "sha256-1exl4ZnLDpUHyFOjRZ+6LjP6SYIQ6IJeG88D7rNzWHY=";
          };
          values = {
            # NOTE just hostpath for now
            openebs-crds.csi.volumeSnapshots.enabled = false;
            localpv-provisioner = {
              hostpathClass.isDefaultClass = true;
              hostpathClass.basePath = "/var/lib/openebs/local";
            };
            zfs-localpv.crds.zfsLocalPv.enabled = false;
            lvm-localpv.crds.lvmLocalPv.enabled = false;
            mayastor.csi.node.initContainers.enabled = false;
            engines.local.lvm.enabled = false;
            engines.local.zfs.enabled = false;
            engines.replicated.mayastor.enabled = false;
          };
          # TODO enable ZFS
          # TODO enable LVM
          # extraResources.storageClasses.openebs-lvm = {
          #   allowVolumeExpansion = true;
          #   parameters.storage = "lvm";
          #   parameters.thinProvision = "yes";
          #   parameters.volgroup = "k8s";
          #   provisioner = "local.csi.openebs.io";
          #   volumeBindingMode = "WaitForFirstConsumer";
          # };
        };

        # Overrides
        kubernetes.api.resources.batch.v1.Job.openebs-pre-upgrade-hook.metadata.annotations."kapp.k14s.io/change-group.openebs-pre-upgrade-hook" = "openebs-pre-upgrade-hook";
        kubernetes.api.resources.apps.v1.Deployment.openebs-localpv-provisioner.metadata.annotations."kapp.k14s.io/change-rule.openebs-pre-upgrade-hook" = "upsert after upserting openebs-pre-upgrade-hook";
      };
    };
  };
}
