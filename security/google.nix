{
  dotfiles = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.platforms.google.enable {
      opentofu.modules = {flake, ...}: {
        resource = {
          google_compute_firewall.root = {
            name = "root";
            network = "\${ google_compute_network.main.id }";
            allow = [
              {
                protocol = "tcp";
                ports = [22 6443];
              }
              {protocol = "icmp";}
            ];
            source_ranges = ["0.0.0.0/0"];
          };
          google_project_service.iap = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "iap.googleapis.com";
          };
          google_iap_brand.main = {
            depends_on = ["google_project_service.iap"];
            support_email = flake.config.canivete.meta.people.my.profiles.default.email;
            application_title = "Dotfiles";
          };
          google_iap_client.main = {
            display_name = "Dotfiles";
            brand = "\${ google_iap_brand.main.name }";
          };
          google_project_service.iam_billing = {
            depends_on = ["google_project_service.resourcemanager_billing"];
            project = "\${ data.google_project.billing.project_id }";
            service = "iam.googleapis.com";
          };
          google_project_service.iam = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "iam.googleapis.com";
          };
          google_service_account.compute = {
            depends_on = ["google_project_service.iam" "google_project_service.iam_billing"];
            account_id = "compute";
            display_name = "VM instances on GCE";
          };
          google_project_service.logging = {
            depends_on = ["google_project_service.resourcemanager"];
            service = "logging.googleapis.com";
          };
        };
      };
    };
  };
}
