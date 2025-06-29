{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.kubelet-csr-approver.enable = lib.mkEnableOption "kubelet-csr-approver";
    config = lib.mkIf config.services.kubelet-csr-approver.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images = {
          kubelet-csr-approver = pkgs.dockerTools.pullImage {
            imageName = "ghcr.io/postfinance/kubelet-csr-approver";
            imageDigest = "sha256:223c497ef54104f141a88e2569c195009c523a498ccffb2f3cbde62d03c72d44";
            hash = "sha256-Ok/EYsNTsMvzXYKvpz1k+2xYpu7tjsd4BOSO593i4go=";
          };
          busybox = pkgs.dockerTools.pullImage {
            imageName = "busybox";
            imageDigest = "sha256:37f7b378a29ceb4c551b1b5582e27747b855bbfaa73fa11914fe0df028dc581f";
            hash = "sha256-VsY+hkpr9nFQizQJ4ROi/qfCxIl7mBnSlllgr8t08Nw=";
          };
        };
      };
      kubenix = {helm, ...}: {
        kubernetes.helm.releases.kubelet-csr-approver = {
          namespace = "security";
          chart = helm.fetch {
            repo = "https://postfinance.github.io/kubelet-csr-approver";
            chart = "kubelet-csr-approver";
            version = "1.2.6";
            sha256 = "sha256-VDkMbt0h998J0GAihLSb/pXq2PcR6BM+q3aC1Hx+L9Y=";
          };
          values = {
            image.tag = "latest";
            metrics.enable = true;
            # metrics.serviceMonitor.enabled = true;
            # TODO is this even necessary?
            # providerRegex = pipe self.nixosConfigurations [
            #   (filterAttrs (_: cfg: cfg.config.canivete.kubernetes.enable))
            #   builtins.attrNames
            #   (concatStringsSep "|")
            #   (str: "^(${str})$")
            # ];
            # bypassDnsResolution = true;
          };
        };
      };
    };
  };
}
