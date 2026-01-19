{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.coredns.enable = lib.mkEnableOption "coredns";
    config = lib.mkIf config.services.coredns.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.coredns = pkgs.dockerTools.pullImage {
          imageName = "coredns/coredns";
          imageDigest = "sha256:40384aa1f5ea6bfdc77997d243aec73da05f27aed0c5e9d65bfa98933c519d97";
          hash = "sha256-owXsrTKUtV/6fPlWRc1YmELlOzpdkSEHwQiFLEvR+O0=";
          finalImageTag = "1.12.0";
        };
      };
      nixidy = {lib, ...}: {
        applications.coredns = {
          canivete.bootstrap.enable = true;
          namespace = "kube-system";
          helm.releases.coredns = {
            chart = lib.helm.downloadHelmChart {
              chart = "coredns";
              version = "1.39.2";
              repo = "https://coredns.github.io/helm";
              chartHash = "sha256-801r6B6OTNB+Ds+G8vRi8ReXN4bLzb6L/8N+Ufu9P5k=";
            };
            values.service.clusterIP = "10.43.0.10";
          };
        };
      };
    };
  };
}
