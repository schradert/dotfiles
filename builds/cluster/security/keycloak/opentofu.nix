{
  config,
  nix,
  ...
}: let
  inherit (nix) flip mapAttrs vals;
  users = {
    tristan = {
      email = "me@trdos.me";
      first_name = "Tristan";
      last_name = "Schrader";
    };
    tahoe = {
      email = "tahoeschrader@gmail.com";
      first_name = "Tahoe";
      last_name = "Schrader";
    };
    adam = {
      email = "adamcschrader@gmail.com";
      first_name = "Adam";
      last_name = "Schrader";
    };
    juju = {
      email = "schrader.julianna@gmail.com";
      first_name = "Julianna";
      last_name = "Schrader";
    };
    dad = {
      email = "cschrad@gmail.com";
      first_name = "Charles";
      last_name = "Schrader";
    };
    mom = {
      email = "arizona.luciana@gmail.com";
      first_name = "Luciana";
      last_name = "Schrader";
    };
  };
  groups.family = ["tristan" "tahoe" "adam" "juju" "dad" "mom"];
  groups.admin = ["tristan" "tahoe"];
  realm_id = "\${ keycloak_realm.primary.id }";
  subdomain = "keycloak.${config.dotfiles.domain}";
  alias = "fido2";
  sub_alias = "fido2-subflow";
in {
  perSystem.dotfiles.opentofu.passwords = {
    keycloak-superadmin.length = 21;
    keycloak-postgres.length = 21;
  };
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["mrparkers/keycloak"];
    modules.keycloak = {
      provider.keycloak = {
        client_id = "admin-cli";
        username = "superadmin";
        password = vals.sops "default.yaml#/passwords/keycloak-superadmin";
        url = "https://${subdomain}";
      };
      resource = {
        keycloak_realm.primary = {
          realm = "primary";
          display_name = "Primary (${subdomain})";
          registration_allowed = false;
        };
        keycloak_group = flip mapAttrs groups (name: _: {inherit realm_id name;});
        keycloak_user = flip mapAttrs users (username: user: user // {inherit realm_id username;});
        keycloak_group_memberships = flip mapAttrs groups (name: members: {
          inherit realm_id members;
          group_id = "\${ keycloak_group.${name}.id }";
        });
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
}
