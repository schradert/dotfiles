{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf toList;
    hostname = "keycloak.${config.domain}";
  in {
    options.services.keycloak.crossplane.enable = mkEnableOption "Crossplane configuration of Keycloak";
    config = mkIf config.services.keycloak.crossplane.enable {
      opentofu = {
        dotfiles.secrets."keycloak/tristan".value = "\${ random_password.keycloak-tristan.result }";
        modules.resource.random_password.keycloak-tristan.length = 21;
      };
      nixidy = {pkgs, ...}: let
        src = pkgs.fetchFromGitHub {
          owner = "crossplane-contrib";
          repo = "provider-keycloak";
          rev = "v2.1.0";
          hash = "sha256-EvDkWuN6n7jM3sddCnhsxomNQIv0tODp9b7GWtZL7J4=";
        };
      in {
        dotfiles.crds.keycloak = {
          inherit src;
          install = true;
          prefix = "package/crds";
          namePrefix = "keycloak";
          attrNameOverrides = {
            "groups.user.keycloak.crossplane.io" = "keycloakUserGroups";
            "roles.defaults.keycloak.crossplane.io" = "keycloakDefaultRoles";
            "roles.group.keycloak.crossplane.io" = "keycloakGroupRoles";
            "roles.user.keycloak.crossplane.io" = "keycloakUserRoles";
          };
        };
        applications.keycloak.resources = {
          providers.keycloak = {
            metadata.namespace = "cicd";
            spec.package = "xpkg.upbound.io/crossplane-contrib/provider-keycloak:v2.1.0";
          };
          keycloakProviderConfigs.keycloak.spec.credentials = {
            source = "Secret";
            secretRef.name = "keycloak-crossplane";
            secretRef.key = "credentials";
            secretRef.namespace = "security";
          };
          externalSecrets.keycloak-crossplane.spec = {
            secretStoreRef.name = "bitwarden";
            secretStoreRef.kind = "ClusterSecretStore";
            data = [
              {
                secretKey = "superadmin";
                remoteRef.key = "keycloak/superadmin";
              }
              {
                secretKey = "tristan";
                remoteRef.key = "keycloak/tristan";
              }
            ];
            target.template.data = {
              client_id = "admin-cli";
              username = "superadmin";
              password = "{{ .superadmin }}";
              tristan = "{{ .tristan }}";
              url = "https" + "://${hostname}";
            };
          };
          keycloakRealms.primary.spec.forProvider = {
            displayName = "Primary (${hostname})";
            realm = "primary";
            enabled = true;
            registrationAllowed = false;
          };
          keycloakUsers.tristan.spec.forProvider = {
            username = "tristan";
            email = "tristanschrader@pm.me";
            firstName = "Tristan";
            lastName = "Schrader";
            realmId = "primary";
            initialPassword = toList {
              temporary = true;
              valueSecretRef.name = "keycloak-crossplane";
              valueSecretRef.key = "tristan";
              valueSecretRef.namespace = "security";
            };
          };
          keycloakGroups = {
            admin.spec.forProvider = {
              name = "admin";
              realmId = "primary";
            };
            family.spec.forProvider = {
              name = "family";
              realmId = "primary";
            };
          };
          keycloakMemberships = {
            admin.spec.forProvider = {
              groupId = "admin";
              members = ["tristan"];
              realmId = "primary";
            };
            family.spec.forProvider = {
              groupId = "family";
              members = ["tristan"];
              realmId = "primary";
            };
          };
          keycloakClientScopes.groups.spec.forProvider = {
            realmId = "primary";
            name = "groups";
            description = "When requested, this scope will map a user's group memberships to a claim";
            includeInTokenScope = true;
          };
          keycloakGroupMembershipProtocolMappers.groups.spec.forProvider = {
            claimName = "groups";
            name = "group-membership-mapper";
            realmId = "primary";
            clientScopeId = "groups";
          };
          keycloakRequiredActions.fido2.spec.forProvider = {
            realmId = "primary";
            alias = "webauthn-register-passwordless";
            enabled = true;
            name = "WebAuthn Register Passwordless";
            defaultAction = true;
          };
          keycloakFlows.fido2.spec.forProvider = {
            alias = "fido2";
            realmId = "primary";
          };
          keycloakBindings.browser.spec.forProvider = {
            realmId = "primary";
            browserFlow = "fido2";
          };
          keycloakExecutions.cookie.spec.forProvider = {
            realmId = "primary";
            parentFlowAlias = "fido2";
            authenticator = "auth-cookie";
            requirement = "ALTERNATIVE";
            priority = 1;
          };
          keycloakSubflows.fido2.spec.forProvider = {
            realmId = "primary";
            alias = "fido2-subflow";
            parentFlowAlias = "fido2";
            requirement = "REQUIRED";
          };
          keycloakExecutions.username.spec.forProvider = {
            realmId = "primary";
            parentFlowAlias = "fido2-subflow";
            authenticator = "username-form";
            requirement = "REQUIRED";
            priority = 2;
          };
          keycloakExecutions.fido2.spec.forProvider = {
            realmId = "primary";
            parentFlowAlias = "fido2-subflow";
            authenticator = "webauthn-passwordless";
            requirement = "REQUIRED";
            priority = 3;
          };
        };
      };
    };
  };
}
