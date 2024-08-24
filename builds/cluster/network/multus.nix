# NOTE https://github.com/bjw-s/home-ops/blob/main/kubernetes/main/apps/network/multus/ks.yaml
#
{
  perSystem = {
    dotfiles.helm.multus = {
      namespace = "network";
      # resources.imports = [
      #   (pkgs.fetchurl {
      #     url = "https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v4.1.0/deployments/multus-daemonset.yml";
      #     sha256 = "";
      #   })
      # ];
      # TODO implement network settings
      values = {};
    };
  };
}
