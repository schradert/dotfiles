{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) domain services;
    inherit (lib) mkIf;
    realm_id = "\${ keycloak_realm.primary.id }";
    client_id = "\${ keycloak_openid_client.oauth2-proxy.client_id }";
  in {
    config = mkIf (services.oauth2-proxy.enable && services.oauth2-proxy.provider == "keycloak") {
      opentofu = mkIf services.keycloak.opentofu.enable {
        dotfiles.secrets = {
          "oauth2-proxy/keycloak/client-id".value = client_id;
          "oauth2-proxy/keycloak/client-secret".value = "\${ keycloak_openid_client.oauth2-proxy.client_secret }";
        };
        modules.resource = {
          keycloak_openid_client.oauth2-proxy = {
            inherit realm_id;
            client_id = "oauth2-proxy";
            name = "OAuth2 Proxy";
            description = "OAuth2 Proxy";
            access_type = "PUBLIC";
            standard_flow_enabled = true;
            valid_redirect_uris = [("https" + "://oauth2-proxy.${domain}/oauth2/callback")];
          };
          keycloak_openid_audience_protocol_mapper.oauth2-proxy = {
            inherit realm_id client_id;
            name = "aud-mapper-${client_id}";
            included_client_audience = client_id;
          };
          keycloak_openid_client_default_scopes.oauth2-proxy = {
            inherit realm_id client_id;
            default_scopes = ["profile" "email" "roles" "web-origins" "\${ keycloak_openid_client_scope.groups.name }"];
          };
        };
      };
      nixidy = mkIf services.keycloak.crossplane.enable {
        applications.oauth2-proxy.resources = {
          keycloakClients.oauth2-proxy.spec.forProvider = {
            enabled = true;
            realmId = "primary";
            clientId = "oauth2-proxy";
            name = "OAuth2 Proxy";
            description = "OAuth2 Proxy";
            accessType = "PUBLIC";
            standardFlowEnabled = true;
            validRedirectUris = [("https" + "://oauth2-proxy.${domain}/oauth2/callback")];
          };
          keycloakProtocolMappers.oauth2-proxy.spec.forProvider = {
            realmId = "primary";
            clientId = "oauth2-proxy";
            name = "aud-mapper-oauth2-proxy";
            config."included.client.audience" = "oauth2-proxy";
          };
          keycloakClientDefaultScopes.oauth2-proxys.spec.forProvider = {
            realmId = "primary";
            clientId = "oauth2-proxy";
            defaultScopes = ["profile" "email" "roles" "web-origins" "groups"];
          };
        };
      };
    };
  };
}
