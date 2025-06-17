{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    options.services.multus.enable = lib.mkEnableOption "Multus Meta-CNI";
    config = lib.mkIf config.services.multus.enable {
      # TODO complete this service. look at bjw-s/home-ops!
      kubenix = {pkgs, ...}: {
        kubernetes.imports = [
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v4.1.0/deployments/multus-daemonset.yml";
            sha256 = "";
          })
        ];
      };
    };
  };
}
