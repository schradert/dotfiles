{
  dotfiles = {canivete, config, lib, ...}: let
    inherit (canivete.vals.sops) default;
    inherit (lib) forEach hasSuffix mapAttrs mkEnableOption mkIf pipe toList;
    hostname = "keycloak.${config.domain}";
  in {
    options.services.keycloak.crossplane.enable = mkEnableOption "Crossplane configuration of Keycloak";
    config = mkIf config.services.keycloak.crossplane.enable {
      opentofu.passwords.keycloak-tristan.length = 21;
      nixidy = {pkgs, ...}: {
        dotfiles.crds.keycloak = {
          src = pkgs.fetchFromGitHub {
            owner = "crossplane-contrib";
            repo = "provider-keycloak";
            rev = "v2.1.0";
            hash = "sha256-EvDkWuN6n7jM3sddCnhsxomNQIv0tODp9b7GWtZL7J4=";
          };
          prefix = "package/crds/";
          crds = [
            "authenticationflow.keycloak.crossplane.io_flows"
            "authenticationflow.keycloak.crossplane.io_subflows"
            # "authenticationflow.keycloak.crossplane.io_bindings"
            "authenticationflow.keycloak.crossplane.io_executions"
            "group.keycloak.crossplane.io_groups"
            "group.keycloak.crossplane.io_memberships"
            "keycloak.crossplane.io_providerconfigs"
            "openidclient.keycloak.crossplane.io_clientscopes"
            "openidgroup.keycloak.crossplane.io_groupmembershipprotocolmappers"
            "realm.keycloak.crossplane.io_realms"
            "realm.keycloak.crossplane.io_requiredactions"
            "user.keycloak.crossplane.io_users"
          ];
        };
        applications.keycloak.resources = {
          "pkg.crossplane.io".v1.Provider.keycloak = {
            metadata.namespace = "cicd";
            spec.package = "xpkg.upbound.io/crossplane-contrib/provider-keycloak:v2.1.0";
          };
          "keycloak.crossplane.io".v1beta1.ProviderConfig.keycloak.spec.credentials = {
            source = "Secret";
            secretRef.name = "keycloak-crossplane";
            secretRef.key = "credentials";
            secretRef.namespace = "security";
          };
          secrets.keycloak-crossplane.data = mapAttrs (_: canivete.toBase64) {
            client_id = "admin-cli";
            username = "superadmin";
            password = default "passwords/keycloak-superadmin";
            url = "https" + "://${hostname}";
          };
          "realm.keycloak.crossplane.io".v1alpha1.Realm.primary.spec.forProvider = {
            displayName = "Primary (${hostname})";
            realm = "primary";
            enabled = true;
            registrationAllowed = false;
          };
          "external-secrets.io".v1.ExternalSecret.keycloak.spec.target.template.data.tristan = default "passwords/keycloak-tristan";
          "user.keycloak.crossplane.io".v1alpha1.User.tristan.spec.forProvider = {
            username = "tristan";
            email = "tristanschrader@pm.me";
            firstName = "Tristan";
            lastName = "Schrader";
            realmId = "primary";
            initialPassword = toList {
              temporary = true;
              valueSecretRef.name = "keycloak";
              valueSecretRef.key = "tristan";
              valueSecretRef.namespace = "security";
            };
          };
          "group.keycloak.crossplane.io".v1alpha1.Group = {
            admin.spec.forProvider = {
              name = "admin";
              realmId = "primary";
            };
            family.spec.forProvider = {
              name = "family";
              realmId = "primary";
            };
          };
          "group.keycloak.crossplane.io".v1alpha1.Memberships = {
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
          "openidclient.keycloak.crossplane.io".v1alpha1.ClientScope.groups.spec.forProvider = {
            realmId = "primary";
            name = "groups";
            description = "When requested, this scope will map a user's group memberships to a claim";
            includeInTokenScope = true;
          };
          "openidgroup.keycloak.crossplane.io".v1alpha1.GroupMembershipProtocolMapper.groups.spec.forProvider = {
            claimName = "groups";
            name = "group-membership-mapper";
            realmId = "primary";
            clientScopeId = "groups";
          };
          "realm.keycloak.crossplane.io".v1alpha1.RequiredAction.fido2.spec.forProvider = {
            realmId = "primary";
            alias = "webauthn-register-passwordless";
            enabled = true;
            name = "WebAuthn Register Passwordless";
            defaultAction = true;
          };
          "authenticationflow.keycloak.crossplane.io".v1alpha1 = {
            Flow.fido2.spec.forProvider = {
              alias = "fido2";
              realmId = "primary";
            };
            # Bindings.browser.spec.forProvider = {
            #   realmId = "primary";
            #   browserFlowId = "fido2";
            # };
            Execution.cookie.spec.forProvider = {
              realmId = "primary";
              parentFlowAlias = "fido2";
              authenticator = "auth-cookie";
              requirement = "ALTERNATIVE";
              priority = 1;
            };
            Subflow.fido2.spec.forProvider = {
              realmId = "primary";
              alias = "fido2-subflow";
              parentFlowAlias = "fido2";
              requirement = "REQUIRED";
            };
            Execution.username.spec.forProvider = {
              realmId = "primary";
              parentFlowAlias = "fido2-subflow";
              authenticator = "username-form";
              requirement = "REQUIRED";
              priority = 2;
            };
            Execution.fido2.spec.forProvider = {
              realmId = "primary";
              parentFlowAlias = "fido2-subflow";
              authenticator = "webauthn-passwordless";
              requirement = "REQUIRED";
              priority = 3;
            };
          };
        };
      };
      kubenix = {pkgs, ...}: {
        canivete.ifd.crds = {
          flows = "authenticationflow.keycloak.crossplane.io/v1alpha1/Flow";
          subflows = "authenticationflow.keycloak.crossplane.io/v1alpha1/Subflow";
          bindings = "authenticationflow.keycloak.crossplane.io/v1alpha1/Bindings";
          executions = "authenticationflow.keycloak.crossplane.io/v1alpha1/Execution";
          groups = "group.keycloak.crossplane.io/v1alpha1/Group";
          memberships = "group.keycloak.crossplane.io/v1alpha1/Memberships";
          providerconfigs = "keycloak.crossplane.io/v1beta1/ProviderConfig";
          clientscopes = "openidclient.keycloak.crossplane.io/v1alpha1/ClientScope";
          groupmembershipprotocolmappers = "openidgroup.keycloak.crossplane.io/v1alpha1/GroupMembershipProtocolMapper";
          realms = "realm.keycloak.crossplane.io/v1alpha1/Realm";
          requiredactions = "realm.keycloak.crossplane.io/v1alpha1/RequiredAction";
          users = "user.keycloak.crossplane.io/v1alpha1/User";
        };
        kubernetes.imports =
          pipe {
            owner = "crossplane-contrib";
            repo = "provider-keycloak";
            rev = "v2.1.0";
            hash = "sha256-EvDkWuN6n7jM3sddCnhsxomNQIv0tODp9b7GWtZL7J4=";
          } [
            pkgs.fetchFromGitHub
            (source: file: source + "/package/crds/" + file + ".yaml")
            (forEach [
              "authenticationflow.keycloak.crossplane.io_flows"
              "authenticationflow.keycloak.crossplane.io_subflows"
              "authenticationflow.keycloak.crossplane.io_bindings"
              "authenticationflow.keycloak.crossplane.io_executions"
              "group.keycloak.crossplane.io_groups"
              "group.keycloak.crossplane.io_memberships"
              "keycloak.crossplane.io_providerconfigs"
              "openidclient.keycloak.crossplane.io_clientscopes"
              "openidgroup.keycloak.crossplane.io_groupmembershipprotocolmappers"
              "realm.keycloak.crossplane.io_realms"
              "realm.keycloak.crossplane.io_requiredactions"
              "user.keycloak.crossplane.io_users"
            ])
          ];
        kubernetes.api.resources = {
          providers.keycloak = {
            metadata.namespace = "cicd";
            spec.package = "xpkg.upbound.io/crossplane-contrib/provider-keycloak:v2.1.0";
          };
          "keycloak.crossplane.io".v1beta1.ProviderConfig.keycloak.spec.credentials = {
            source = "Secret";
            secretRef.name = "keycloak-crossplane";
          };
          secrets.keycloak-crossplane.data = mapAttrs (_: canivete.toBase64) {
            client_id = "admin-cli";
            username = "superadmin";
            password = default "passwords/keycloak-superadmin";
            url = "https" + "://${hostname}";
          };
          "realm.keycloak.crossplane.io".v1alpha1.Realm.primary.spec.forProvider = {
            displayName = "Primary (${hostname})";
            realm = "primary";
            enabled = true;
            registrationAllowed = false;
          };
          externalsecrets.keycloak.spec.target.template.data.tristan = default "passwords/keycloak-tristan";
          "user.keycloak.crossplane.io".v1alpha1.User.tristan.spec.forProvider = {
            username = "tristan";
            email = "tristanschrader@pm.me";
            firstName = "Tristan";
            lastName = "Schrader";
            realmId = "primary";
            initialPassword = toList {
              temporary = true;
              valueSecretRef.name = "keycloak";
              valueSecretRef.key = "tristan";
            };
          };
          "group.keycloak.crossplane.io".v1alpha1.Group = {
            admin.spec.forProvider = {
              name = "admin";
              realmId = "primary";
            };
            family.spec.forProvider = {
              name = "family";
              realmId = "primary";
            };
          };
          "group.keycloak.crossplane.io".v1alpha1.Memberships = {
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
          "openidclient.keycloak.crossplane.io".v1alpha1.ClientScope.groups.spec.forProvider = {
            realmId = "primary";
            name = "groups";
            description = "When requested, this scope will map a user's group memberships to a claim";
            includeInTokenScope = true;
          };
          "openidgroup.keycloak.crossplane.io".v1alpha1.GroupMembershipProtocolMapper.groups.spec.forProvider = {
            claimName = "groups";
            name = "group-membership-mapper";
            realmId = "primary";
            clientScopeId = "groups";
          };
          "realm.keycloak.crossplane.io".v1alpha1.RequiredAction.fido2.spec.forProvider = {
            realmId = "primary";
            alias = "webauthn-register-passwordless";
            enabled = true;
            name = "WebAuthn Register Passwordless";
            defaultAction = true;
          };
          "authenticationflow.keycloak.crossplane.io".v1alpha1 = {
            Flow.fido2.spec.forProvider = {
              alias = "fido2";
              realmId = "primary";
            };
            Bindings.browser.spec.forProvider = {
              realmId = "primary";
              browserFlowId = "fido2";
            };
            Execution.cookie.spec.forProvider = {
              realmId = "primary";
              parentFlowAlias = "fido2";
              authenticator = "auth-cookie";
              requirement = "ALTERNATIVE";
              priority = 1;
            };
            Subflow.fido2.spec.forProvider = {
              realmId = "primary";
              alias = "fido2-subflow";
              parentFlowAlias = "fido2";
              requirement = "REQUIRED";
            };
            Execution.username.spec.forProvider = {
              realmId = "primary";
              parentFlowAlias = "fido2-subflow";
              authenticator = "username-form";
              requirement = "REQUIRED";
              priority = 2;
            };
            Execution.fido2.spec.forProvider = {
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
  };
}
