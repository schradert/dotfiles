{config, ...}: let
  subdomain = "bitwarden.${config.dotfiles.domain}";
in {
  perSystem.dotfiles.helm.bitwarden = {
    namespace = "security";
    chart = {
      repo = "https://charts.bitwarden.com";
      chart = "self-host";
      version = "2024.7.2";
      sha256 = "oj2mx2qBdi76LO6bbcr266dp0GO4Cq3H15mUyhM7ziM=";
    };
    values = {
      general = {
        domain = subdomain;
        ingress.enabled = false;
        admin = "t0rdos@pm.me";
        # TODO set up SMTP server with email account
        # email = {
        #   replyToEmail = "REPLACE";
        #   smtpHost = "REPLACE";
        #   smtpPort = "REPLACE";
        #   smtpSsl = "REPLACE";
        # };
      };
      sharedStorageClassName = "seaweedfs-storage";
      component.scim.enabled = true;
      secrets.secretName = "bitwarden";
    };
    resources.secrets.bitwarden.stringData = {
      # TODO reach out to Bitwarden to approve self-hosting
      globalSettings__installation__id = "REPLACE";
      globalSettings__installation__key = "REPLACE";
      # TODO set up SMTP server with email account
      globalSettings__mail__smtp__username = "REPLACE";
      globalSettings__mail__smtp__password = "REPLACE";
      # TODO find my YubiKey credentials
      globalSettings__yubico__clientId = "REPLACE";
      globalSettings__yubico__key = "REPLACE";
      # TODO set up HIBP account
      globalSettings__hibpApiKey = "REPLACE";
      # TODO find how to grab the database password
      SA_PASSWORD = "REPLACE";
    };
    # TODO Kubectl didn't understand just a plain Y? I guess it thinks it's a boolean
    # resources.configMaps.bitwarden-config-map.data.ACCEPT_EULA = mkForce "'Y'";
    # TODO Routing
    # middlewares.bitwarden.metadata.namespace = "bitwarden";
    # middlewares.bitwarden.spec.stripPrefix.prefixes = ["/api" "/attachments" "/icons" "/notifications" "/events" "/scim"];
    # ingressroutes.bitwarden.metadata.namespace = "bitwarden";
    # ingressroutes.bitwarden.spec = {
    #   entryPoints = ["websecure"];
    #   tls.certResolver = "letsencrypt-staging-tls";
    #   routes = let
    #     mkService = path: overrides: toList (flip mergeAttrs overrides {
    #       name = "bitwarden-self-host-${path}";
    #       port = 5000;
    #     });
    #     mkRoute = path: overrides: flip mergeAttrs (overrides.route or {}) {
    #       match = "Host(`${subdomain}`) && PathPrefix(`/${path}/`)";
    #       kind = "Rule";
    #       services = mkService path (overrides.service or {});
    #     };
    #   in [
    #     (mkRoute "web" {
    #       route.match = "Host(`${subdomain}`) && PathPrefix(`/`)";
    #       service.passHostHeader = true;
    #     })
    #     (mkRoute "api" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "attachments" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "icons" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "notifications" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "events" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "scim" {route.middlewares = [{name = "bitwarden";}];})
    #     (mkRoute "sso" {})
    #     (mkRoute "identity" {})
    #     (mkRoute "admin" {route.match = "Host(`${subdomain}`) && PathPrefix(`/admin`)";})
    #   ];
    # };
  };
}
