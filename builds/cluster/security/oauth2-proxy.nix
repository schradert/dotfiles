{
  perSystem.canivete.kubenix.clusters.prod.modules.oauth2-proxy = {helm, ...}: {
    kubernetes.helm.releases.oauth2-proxy = {
      chart = helm.fetch {
        repo = "https://oauth2-proxy.github.io/manifests";
        chart = "oauth2-proxy";
        version = "7.7.9";
        sha256 = "d+SK/ngRuX9Wsy0l52n5SPwTopOtJHHgZBGhjHfshyA=";
      };
      # values.clientID = "";
      # values.clientSecret = "";
      # values.config.configFile = pkgs.writers.writeYAML "oauth2-proxy.cfg" {
      #   provider = "keycloak-oidc";
      #   redirect_url = "https://keycloak.${domain}/oauth2/callback";
      #   oidc_issuer_url = "https://keycloak.${domain}/realms/master";
      #   email_domain = "trdos.me";
      #   code_challenge_method = "S256";
      # };
    };
  };
}
