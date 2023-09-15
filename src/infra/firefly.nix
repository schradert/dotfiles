{ config, lib, pkgs, ... }:
{
  config.resource.helm_release.firefly = {
    name = "firefly";
    repository = "https://firefly-iii.github.io/kubernetes";
    version = "0.7.2";
    chart = "firefly-iii-stack";
  };
}
