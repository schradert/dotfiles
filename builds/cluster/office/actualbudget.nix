{config, ...}: let
  inherit (config.dotfiles) domain;
in {
  perSystem.canivete.kubenix.clusters.prod.modules.actualbudget = {
    helm,
    nix,
    pkgs,
    ...
  }: {
    # Can't verify schema over the internet during build
    # TODO patch to verify using schema definition file paths
    kubernetes.helm.releases.actualbudget.chart = pkgs.stdenv.mkDerivation rec {
      inherit (src) name;
      src = helm.fetch {
        repo = "https://beluga-cloud.github.io/charts";
        chart = "actual";
        version = "2.0.0";
        sha256 = "NZ+886bgZwg5CotPqs1IyiJKUmWrsRPiFzEeOAUXpnQ=";
      };
      buildPhase = ''
        mkdir -p $out
        cp -r $src/* $out
        rm -f $out/values.schema.*
      '';
    };
  };
}
