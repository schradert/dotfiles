{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.argocd.enable = lib.mkEnableOption "reloader";
    config = lib.mkIf config.services.argocd.enable {
      nixos = {pkgs, ...}: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        canivete.kubernetes.images = {
          argocd = pullImage {
            imageName = "quay.io/argoproj/argocd";
            imageDigest = "sha256:a45307e2695d0fd93713e3d211b71086ac75a85dc8afbb28a249bdc4b3b0b2b9";
            hash = "sha256-61VnixjxXlB9kxG/OU5K3lLVwbmZCXr6DmubjtEbTo4=";
            finalImageTag = "v3.0.6";
          };
          argocd-redis-alpine = pullImage {
            imageName = "ecr-public.aws.com/docker/library/redis";
            imageDigest = "sha256:c88ea2979a49ca497bbf7d39241b237f86c98e58cb2f6b1bc2dd167621f819bb";
            hash = "sha256-PHeNmUnBQ8d81hx8hEfhmnjMaFK16hMmVP+8KWDdp7c=";
            finalImageTag = "7.2.8-alpine";
          };
          argocd-dex = pullImage {
            imageName = "ghcr.io/dexidp/dex";
            imageDigest = "sha256:0881d3c9359b436d585b2061736ce271c100331e073be9178ef405ce5bf09557";
            hash = "sha256-m7wqrDupLBNC8ubG577jJTkFc4pIgSyjjjdxFmkQ43c=";
            finalImageTag = "v2.43.1";
          };
        };
      };
      nixidy = {charts, ...}: {
        applications.argo = {
          dotfiles.bootstrap.enable = true;
          namespace = "cicd";
          helm.releases.argod = {
            chart = charts.argoproj.argo-cd;
            values = {
              global.domain = "argocd.${config.domain}";
              global.image.pullPolicy = "Never";
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
