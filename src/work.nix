{
  flake.homeModules.work = {
    config,
    pkgs,
    nix,
    flake,
    ...
  }: {
    options.dotfiles.work.enable = nix.mkEnableOption "work packages";
    config = nix.mkIf config.dotfiles.work.enable {
      nixpkgs.overlays = [flake.inputs.gke-gcloud-auth-plugin-flake.overlays.default];
      home.packages = with pkgs; [google-cloud-sdk gke-gcloud-auth-plugin];
    };
  };
}
