{
  # NOTE https://www.keycloak.org/2024/09/realm-config-management-tools-survey-results
  dotfiles = {
    config,
    lib,
    ...
  }: let
    realm_id = "\${ keycloak_realm.primary.id }";
    hostname = "keycloak.${config.domain}";
  in {
    options.services.keycloak.opentofu.enable = lib.mkEnableOption "OpenTofu configuration of Keycloak";
    config = lib.mkIf config.services.keycloak.opentofu.enable {
      opentofu.passwords.keycloak-tristan.length = 21;
      opentofu.plugins = ["mrparkers/keycloak"];
      opentofu.modules = {
        provider.keycloak = {
          client_id = "admin-cli";
          username = "superadmin";
          password = "\${ random_password.keycloak-superadmin.result }";
          url = "https" + "://${hostname}";
        };
        resource = {
          keycloak_realm.primary = {
            realm = "primary";
            enabled = true;
            display_name = "Primary (${hostname})";
            registration_allowed = false;
          };
          keycloak_user.tristan = {
            inherit realm_id;
            username = "tristan";
            email = "tristanschrader@pm.me";
            first_name = "Tristan";
            last_name = "Schrader";
            # TODO initial password
          };
          keycloak_group.admin = {
            inherit realm_id;
            name = "admin";
          };
          keycloak_group.family = {
            inherit realm_id;
            name = "family";
          };
          keycloak_group_memberships.admin = {
            inherit realm_id;
            members = ["tristan"];
            group_id = "\${ keycloak_group.admin.id }";
          };
          keycloak_group_memberships.family = {
            inherit realm_id;
            members = ["tristan"];
            group_id = "\${ keycloak_group.family.id }";
          };
          keycloak_openid_client_scope.groups = {
            inherit realm_id;
            name = "groups";
            description = "When requested, this scope will map a user's group memberships to a claim";
            include_in_token_scope = true;
          };
          keycloak_openid_group_membership_protocol_mapper.groups = {
            realm_id = "\${ keycloak_realm.primary.id }";
            client_scope_id = "\${ keycloak_openid_client_scope.groups.id }";
            name = "group-membership-mapper";
            claim_name = "groups";
          };
          keycloak_required_action.fido2 = {
            inherit realm_id;
            alias = "webauthn-register-passwordless";
            enabled = true;
            name = "WebAuthn Register Passwordless";
            default_action = true;
          };
          keycloak_authentication_bindings.browser = {
            inherit realm_id;
            browser_flow = "\${ keycloak_authentication_flow.fido2.alias }";
          };
          keycloak_authentication_flow.fido2 = {
            inherit realm_id;
            alias = "fido2";
          };
          keycloak_authentication_execution.cookie = {
            inherit realm_id;
            parent_flow_alias = "\${ keycloak_authentication_flow.fido2.alias }";
            authenticator = "auth-cookie";
            requirement = "ALTERNATIVE";
          };
          keycloak_authentication_subflow.fido2 = {
            inherit realm_id;
            alias = "fido2-subflow";
            parent_flow_alias = "\${ keycloak_authentication_flow.fido2.alias }";
            requirement = "REQUIRED";
            depends_on = ["keycloak_authentication_execution.cookie"];
          };
          keycloak_authentication_execution.username = {
            inherit realm_id;
            parent_flow_alias = "\${ keycloak_authentication_subflow.fido2.alias }";
            authenticator = "username-form";
            requirement = "REQUIRED";
          };
          keycloak_authentication_execution.fido2 = {
            inherit realm_id;
            parent_flow_alias = "\${ keycloak_authentication_subflow.fido2.alias }";
            authenticator = "webauthn-passwordless";
            requirement = "REQUIRED";
            depends_on = ["keycloak_authentication_execution.username"];
          };
        };
      };
    };
  };
}
