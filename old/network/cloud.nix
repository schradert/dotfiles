{
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config.network.static) enable provider;
    inherit (lib) flatten mkEnableOption mkIf mkMerge optional types;
    providers = flatten [
      (optional config.clouds.hetzner.enable "hetzner")
      (optional config.clouds.google.enable "google")
    ];
  in {
    options.network.static = {
      enable = mkEnableOption "Static IP address";
      provider = canivete.mkNullableOption (types.enum providers) {description = "Cloud provider with static IP";};
    };
    config = mkIf enable (mkMerge [
      (mkIf (provider == "google") {
        opentofu.modules = {
          locals.root_ip = "\${ google_compute_address.root.address }";
          resource.google_project_service.compute = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "compute.googleapis.com";
          };
          resource.google_compute_address.root = {
            depends_on = ["google_project_service.compute"];
            name = "root";
            network_tier = "PREMIUM";
          };
        };
      })
      (mkIf (provider == "hetzner") {
        opentofu.modules.locals.root_ip = "\${ hcloud_primary_ip.root.ip_address }";
        opentofu.modules.resource.hcloud_primary_ip.root = {
          name = "root";
          type = "ipv4";
          assignee_type = "server";
          datacenter = "ash-dc1";
          auto_delete = false;
        };
      })
    ]);
  };
}
