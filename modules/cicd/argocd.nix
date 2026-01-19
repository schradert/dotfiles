{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    images = {
      argocd = {
        imageName = "quay.io/argoproj/argocd";
        imageDigest = "sha256:1cb4ede2fc4a6332c128d9ba29d19e8cb5b76f9260dc47550a4b3b154269ff86";
        hash = "sha256-CaAuAnOK2dvS5MaNc4e6xEJs1qAx1K3SNI6t4vGGS+c=";
        finalImageTag = "v3.0.11";
      };
      argocd-redis-alpine = {
        imageName = "ecr-public.aws.com/docker/library/redis";
        imageDigest = "sha256:c88ea2979a49ca497bbf7d39241b237f86c98e58cb2f6b1bc2dd167621f819bb";
        hash = "sha256-PHeNmUnBQ8d81hx8hEfhmnjMaFK16hMmVP+8KWDdp7c=";
        finalImageTag = "7.2.8-alpine";
      };
      argocd-dex = {
        imageName = "ghcr.io/dexidp/dex";
        imageDigest = "sha256:0881d3c9359b436d585b2061736ce271c100331e073be9178ef405ce5bf09557";
        hash = "sha256-m7wqrDupLBNC8ubG577jJTkFc4pIgSyjjjdxFmkQ43c=";
        finalImageTag = "v2.43.1";
      };
    };
  in {
    options.services.argocd.enable = lib.mkEnableOption "reloader";
    config = lib.mkIf config.services.argocd.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      nixidy = {charts, ...}: {
        applications.argo = {
          canivete.bootstrap.enable = true;
          namespace = "cicd";
          helm.releases.argod = {
            chart = charts.argoproj.argo-cd;
            values = {
              global.domain = "argocd.${config.domain}";
              global.image = {
                repository = images.argocd.imageName;
                tag = images.argocd.finalImageTag;
                pullPolicy = "Never";
              };
              # TODO convert to dragonflydb?
              redis.image.repository = images.argocd-redis-alpine.imageName;
              redis.image.tag = images.argocd-redis-alpine.finalImageTag;
              dex.image.repository = images.argocd-dex.imageName;
              dex.image.tag = images.argocd-dex.finalImageTag;
              configs.cmp.create = true;
              # TODO fix this auto-generation manifests
              # configs.cmp.plugins.nixidy.generate.command = ["sh" "-c" "nix run .#nixidy -- build .#prod"];
            };
          };
        };
      };
    };
  };
}
