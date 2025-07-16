{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config.storage) bucket;
    inherit (lib) flip mapAttrsToList mkDefault mkEnableOption mkIf mkMerge mkOption pipe setAttrByPath types;
    inherit (types) attrsOf coercedTo int listOf str submodule;
  in {
    options.services.volsync.enable = mkEnableOption "Volsync";
    config = mkMerge [
      {
        nixidy = _: {
          nixidy.applicationImports = [
            ({config, ...}: {
              options.dotfiles.volsync = {
                enable = mkEnableOption "Volsync replication of PVCs" // {default = config.dotfiles.volsync.pvcs != null;};
                pvcs =
                  pipe ({config, ...}: {
                    options = {
                      title = mkOption {
                        description = "Name of PVC (eventually) created";
                        type = str;
                      };
                      path = mkOption {
                        default = ["persistentVolumeClaims" config.title];
                        description = "Location to inject dataSourceRef for ReplicationDestination";
                        type = listOf str;
                      };
                      uid = mkOption {
                        default = 101;
                        description = "UID for podSecurityContext";
                        type = int;
                      };
                      gid = mkOption {
                        default = 101;
                        description = "GID for podSecurityContext";
                        type = int;
                      };
                      # TODO switch to a resizable, snapshottable storage class
                      # NOTE openebs-hostpath Local PV is neither and doesn't support custom dataSourceRef
                      # options.inject = canivete.mkEnabledOption "Inject dataSourceRef into a PVC";
                      inject = mkEnableOption "Inject dataSourceRef into a PVC";
                    };
                  }) [
                    submodule
                    (coercedTo str (title: {inherit title;}))
                    attrsOf
                    (flip canivete.mkNullableOption {
                      description = "Name of PVCs to replicate and back up";
                      default = {};
                    })
                  ];
              };
            })
          ];
        };
      }
      (mkIf config.services.volsync.enable {
        storage.bucket.buckets.volsync = "volsync";
        opentofu = {
          dotfiles.secrets.restic.value = "\${ random_password.restic.result }";
          modules.resource.random_password.restic.length = 21;
        };
        # TODO prevent hardcoding bucket provider
        opentofu.modules.resource.null_resource.kubernetes.depends_on = ["b2_bucket.volsync"];
        nixos = {pkgs, ...}: let
          inherit (pkgs.dockerTools) pullImage;
        in {
          canivete.kubernetes.images = {
            kube-rbac-proxy = pullImage {
              imageName = "quay.io/brancz/kube-rbac-proxy";
              imageDigest = "sha256:7de54b6dedc8006ffd447267b826eb417a648c00f2b735b6d313395411803719";
              hash = "sha256-a3euZnjY/O/gVcXGx70ycuJbo05f2E0BHffM0FVbla0=";
              finalImageTag = "v0.18.2";
            };
            volsync = pullImage {
              imageName = "quay.io/backube/volsync";
              imageDigest = "sha256:2dd1ef4251b3a5881ab9289dce481de3fe30da7fc8da5e4dfed2d562964c888a";
              hash = "sha256-G/z2RbEyp53S3l2OACtuoFSddpuVY4gQ5Yc9PiddYn0=";
              finalImageTag = "0.12.1";
            };
          };
        };
        nixidy = {
          lib,
          pkgs,
          ...
        }: {
          dotfiles.crds.volsync = {
            prefix = "config/crd/bases";
            src = pkgs.fetchFromGitHub {
              owner = "backube";
              repo = "volsync";
              rev = "v0.12.1";
              hash = "sha256-8aqZakHtqFII+7NxAFjQuaJtAAhrZubEvJIQe5COqJ8=";
            };
          };
          applications.volsync = {
            namespace = "storage";
            helm.releases.volsync.chart = lib.helm.downloadHelmChart {
              chart = "volsync";
              version = "0.12.1";
              repo = "https://backube.github.io/helm-charts";
              chartHash = "sha256-+ytyqmvUPZynLDivVXjEhmd1uHH3MaaCsYo35Na6sX4=";
            };
          };
          nixidy.applicationImports = [
            ({
              config,
              name,
              ...
            }: let
              inherit (config.dotfiles) volsync;
            in {
              config = mkIf (volsync.enable && volsync.pvcs != null) {
                resources = mkMerge (flip mapAttrsToList volsync.pvcs (pvc: {
                  title,
                  inject,
                  path,
                  uid,
                  gid,
                }: let
                  repository = "volsync--${name}--${pvc}";
                in
                  mkMerge [
                    # Some services use operators that allow configuration injection into PersistentVolumeClaim templates
                    # Some still don't offer ways to inject so we have to do this manually
                    (mkIf inject (setAttrByPath path {
                      spec.dataSourceRef = {
                        kind = "ReplicationDestination";
                        apiGroup = "volsync.backube";
                        name = "${repository}-dst";
                      };
                    }))
                    # TODO transfer all of these to respective modules
                    # TODO do the same for rook-ceph
                    {
                      externalSecrets.${repository}.spec = {
                        secretStoreRef.name = "bitwarden";
                        secretStoreRef.kind = "ClusterSecretStore";
                        data = [
                          {
                            secretKey = "restic";
                            remoteRef.key = "restic";
                          }
                          {
                            secretKey = "password";
                            remoteRef.key = "bucket";
                          }
                        ];
                        target.template.data = {
                          RESTIC_REPOSITORY = "s3:https://${bucket.server}/${bucket.buckets.volsync}/${repository}";
                          RESTIC_PASSWORD = "{{ .restic }}";
                          AWS_ACCESS_KEY_ID = bucket.user;
                          AWS_SECRET_ACCESS_KEY = "{{ .password }}";
                          AWS_DEFAULT_REGION = bucket.region;
                        };
                      };
                      replicationSources."${repository}-src".spec = {
                        sourcePVC = title;
                        trigger.schedule = "0 4 * * *";
                        restic = {
                          # TODO is it worth using OpenEBS Mayastor for PiT Snapshot/Clone?
                          # Copy every day at 4am, pruning every 8 days down to 1 per day/week/month/year
                          moverSecurityContext.fsGroup = gid;
                          copyMethod = "Direct";
                          pruneIntervalDays = 8;
                          inherit repository;
                          retain = {
                            daily = 1;
                            weekly = 1;
                            monthly = 1;
                            yearly = 1;
                          };
                        };
                      };
                      replicationDestinations."${repository}-dst".spec = {
                        # Override this to track restoration
                        trigger.manual = mkDefault "1";
                        restic = {
                          moverSecurityContext.runAsGroup = gid;
                          moverSecurityContext.runAsUser = uid;
                          copyMethod = "Direct";
                          destinationPVC = title;
                          inherit repository;
                        };
                      };
                    }
                  ]));
              };
            })
          ];
        };
      })
    ];
  };
}
