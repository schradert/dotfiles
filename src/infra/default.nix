{ config, lib, pkgs, ... }:
{
  config.provider.kubernetes = { config_path = "~/.kube/config"; context_name = "k3d-personal-local"; };
  config.provider.helm = { inherit (config.provider) kubernetes; };
  config.resource.helm_release.firefly = {
    name = "firefly";
    repository = "https://firefly-iii.github.io/kubernetes";
    version = "0.7.2";
    chart = "firefly-iii-stack";
    values = pkgs.lib.backbone.toYAML {

    };
  };
}
