{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkDefault mkEnableOption mkIf toList;
    images = {
      dragonflydb-kube-rbac-proxy = {
        imageName = "quay.io/brancz/kube-rbac-proxy";
        imageDigest = "sha256:7de54b6dedc8006ffd447267b826eb417a648c00f2b735b6d313395411803719";
        hash = "sha256-a3euZnjY/O/gVcXGx70ycuJbo05f2E0BHffM0FVbla0=";
        finalImageTag = "v0.18.2";
      };
      dragonflydb-operator = {
        imageName = "docker.dragonflydb.io/dragonflydb/operator";
        imageDigest = "sha256:11cef45ec1079b9d97930fc99ecd08ba29d4eca55cdb45887cb0ac40ee4e4d24";
        hash = "sha256-cLrMawoltRYV7+3ru7oTWJIaCuq2Pg4pd3fF3lEWW2c=";
        finalImageTag = "v1.1.11";
      };
      dragonflydb = {
        imageName = "docker.dragonflydb.io/dragonflydb/dragonfly";
        imageDigest = "sha256:248f15d00d7bf6cbe680b87afa742c25d21c25465904d916ec7f8e36a6c1fce0";
        hash = "sha256-91Lt9PkpifyNTm5bw3922d6TKOljD5oznTUDY2QmkYs=";
        finalImageTag = "v1.31.2";
      };
    };
  in {
    options.services.dragonflydb.enable = mkEnableOption "DragonflyDB";
    config = mkIf services.dragonflydb.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      nixidy = {pkgs, ...}: let
        repo = pkgs.fetchFromGitHub {
          owner = "dragonflydb";
          repo = "dragonfly-operator";
          rev = "9874757bf4606ced0cd3bb679c2bb36b5d4f3edc";
          hash = "sha256-Ts98Rt6MeOJvraPrh5hAoapAKkQIcjJ+bB0V6/4q64k=";
        };
      in {
        dotfiles.crds.dragonflydb = {
          src = repo;
          prefix = "manifests";
          match = "^crd\.yaml$";
        };
        applications.dragonflydb = {
          namespace = "storage";
          helm.releases.dragonflydb = {
            chart = pkgs.runCommand "dragonfly-operator" {} "cp -aL ${repo}/charts/dragonfly-operator $out";
            values = {
              rbacProxy.image = with images.dragonflydb-kube-rbac-proxy; {
                repository = imageName;
                pullPolicy = "Never";
                tag = finalImageTag;
              };
              manager.image = with images.dragonflydb-operator; {
                repository = imageName;
                pullPolicy = "Never";
                tag = finalImageTag;
              };
              serviceMonitor.enabled = services.prometheus.enable;
              grafanaDashboard.enabled = services.grafana.enable;
              # TODO should I add the operator?
              # grafanaDashboard.grafanaOperator.enabled = true;
            };
          };
        };
        nixidy.applicationImports = [
          (_: {
            defaults = toList {
              kind = "Dragonfly";
              default.spec.image = with images.dragonflydb; mkDefault "${imageName}:${finalImageTag}";
            };
          })
        ];
      };
    };
  };
}
