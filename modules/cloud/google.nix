{config, ...}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
in {
  dotfiles = {
    canivete,
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config) domain;
    inherit (config.clouds.google) enable project billing_project;
  in {
    options.clouds.google = {
      enable = lib.mkEnableOption "Google Cloud";
      project = canivete.mkNullableOption lib.types.str {description = "Main infrastructure project";};
      billing_project = canivete.mkNullableOption lib.types.str {description = "Billing infrastructure project";};
    };
    config = lib.mkIf enable {
      devenv.packages = [pkgs.google-cloud-sdk];
      opentofu.plugins = ["opentofu/google"];
      opentofu.modules = {
        provider.google = {
          inherit project billing_project;
          region = "us-west1";
          zone = "us-west1-a";
          user_project_override = true;
        };
        # TODO why do I need certain services on billing project?
        # NOTE required permissions are:
        # roles/resourcemanager.organizationAdmin + roles/billing.admin on organizations/{organization}
        # roles/billing.user on billingAccounts/{billing_account}
        data = {
          google_organization.main.domain = domain;
          google_project.billing.project_id = "";
          google_project_service.billing = {
            service = "cloudbilling.googleapis.com";
            project = billing_project;
          };
          google_project_service.resourcemanager_billing = {
            service = "cloudresourcemanager.googleapis.com";
            project = billing_project;
          };
          google_billing_account.main.display_name = "";
        };
        resource = {
          google_project.main = {
            depends_on = ["google_org_policy_policy.service_account_key"];
            name = project;
            project_id = project;
            org_id = "\${ data.google_organization.main.org_id }";
            billing_account = "\${ data.google_billing_account.main.id }";
          };
          google_project_service.iam_billing = {
            depends_on = ["google_project_service.resourcemanager_billing"];
            project = "\${ data.google_project.billing.project_id }";
            service = "iam.googleapis.com";
          };
          google_project_service.resourcemanager = {
            service = "cloudresourcemanager.googleapis.com";
            project = "\${ google_project.main.project_id }";
          };
          google_project_service.resourcemanager_billing = {
            project = "\${ data.google_project.billing.project_id }";
            service = "cloudresourcemanager.googleapis.com";
          };
          google_project_service.orgpolicy = {
            depends_on = ["google_project_service.resourcemanager_billing"];
            project = "\${ data.google_project.billing.project_id }";
            service = "orgpolicy.googleapis.com";
          };
          google_organization_iam_member.orgpolicy = {
            org_id = "\${ data.google_organization.main.org_id }";
            role = "roles/orgpolicy.policyAdmin";
            member = "user:${email}";
          };
          google_org_policy_policy.service_account_key = {
            depends_on = ["google_project_service.orgpolicy" "google_organization_iam_member.orgpolicy"];
            name = "\${ data.google_organization.main.name }/policies/iam.disableServiceAccountKeyCreation";
            parent = "\${ data.google_organization.main.name }";
            spec.rules.enforce = "FALSE";
          };
        };
      };
    };
  };
}
