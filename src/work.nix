{
  inputs,
  lib,
  ...
}: let
  option = lib.mkEnableOption "work packages";
in {
  flake.homeModules.work = {
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.work.enable {
      nixpkgs.overlays = [inputs.gke-gcloud-auth-plugin-flake.overlays.default];
      home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin];
    };
  };
  flake.nixosModules.nixos-work.options.dotfiles.work.enable = option;
  flake.darwinModules_.darwin-work.options.dotfiles.work.enable = option;
}
