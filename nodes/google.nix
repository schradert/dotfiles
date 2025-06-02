{
  perSystem = {pkgs, ...}: {
    canivete.devShells.shells.default.packages = [pkgs.google-cloud-sdk];
  };
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain;
    # Somehow someone already took this... :'(
    project = "roca-dotfiles";
    billing_project = "rocaille";
  in {
    options.platforms.google.enable = lib.mkEnableOption "Google Cloud";
    config.opentofu.modules = {
      provider.google = {
        inherit project billing_project;
        region = "us-west1";
        zone = "us-west1-a";
        user_project_override = true;
      };
      # TODO why do I need certain services on billing project?
      # NOTE required permissions are:
      # roles/resourcemanager.organizationAdmin + roles/billing.admin on organizations/rocamaterials.com
      # roles/billing.user on billingAccounts/{Roca AmEx}
      data = {
        google_organization.main.domain = domain;
        google_project.billing.project_id = "rocaille";
        google_project_service.billing = {
          service = "cloudbilling.googleapis.com";
          project = billing_project;
        };
        google_project_service.resourcemanager_billing = {
          service = "cloudresourcemanager.googleapis.com";
          project = billing_project;
        };
        google_billing_account.main.display_name = "Roca AmEx ";
      };
      resource.google_project.main = {
        name = project;
        project_id = project;
        org_id = "\${ data.google_organization.main.org_id }";
        billing_account = "\${ data.google_billing_account.main.id }";
      };
      resource.google_project_service.resourcemanager = {
        service = "cloudresourcemanager.googleapis.com";
        project = "\${ google_project.main.project_id }";
      };
    };
  };
}
