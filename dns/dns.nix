{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) root domain;
    cluster_subdomain = "k8s";
    network_subdomain = "vpn";
  in {
    # TODO is there a better place to keep fetchKubeconfig?
    # NOTE cannot split this into multiline because it is injected into a script
    kubenix.canivete.deploy.fetchKubeconfig = "ssh root@${root}.${network_subdomain}.${domain} k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${cluster_subdomain}.${domain}/g'";
    nixos.canivete.kubernetes.k3s.tls-san = lib.mkForce ["${cluster_subdomain}.${domain}"];
    opentofu.plugins = ["hashicorp/google"];
    opentofu.modules.resource = {
      google_project_service.dns = {
        depends_on = ["google_project_service.resourcemanager"];
        service = "dns.googleapis.com";
      };
      google_dns_managed_zone.main = {
        depends_on = ["google_project_service.dns"];
        name = lib.replaceStrings ["."] ["-"] domain;
        dns_name = "${domain}.";
      };
      null_resource.kubernetes.depends_on = ["google_dns_record_set.k8s-a"];
      google_dns_record_set = {
        root-a = {
          name = "\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "A";
          ttl = 240;
          # Squarespace
          rrdatas = [
            "198.49.23.144"
            "198.49.23.145"
            "198.185.159.144"
            "198.185.159.145"
          ];
        };
        www-c = {
          name = "www.\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "CNAME";
          ttl = 240;
          rrdatas = ["ext-sq.squarespace.com."];
        };
        wildcard-vpn-a = {
          name = "*.${network_subdomain}.\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "A";
          ttl = 240;
          rrdatas = ["\${ local.root_ip }"];
        };
        k8s-a = {
          name = "${cluster_subdomain}.\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "A";
          ttl = 240;
          rrdatas = ["\${ local.root_ip }"];
        };
        # Google Workspace
        root-mx = {
          name = "\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "MX";
          ttl = 240;
          rrdatas = [
            "1 aspmx.l.google.com."
            "5 alt1.aspmx.l.google.com."
            "5 alt2.aspmx.l.google.com."
            "10 alt3.aspmx.l.google.com."
            "10 alt4.aspmx.l.google.com."
          ];
        };
        root-txt = {
          name = "\${ google_dns_managed_zone.main.dns_name }";
          managed_zone = "\${ google_dns_managed_zone.main.name }";
          type = "TXT";
          ttl = 240;
          rrdatas = ["google-site-verification=5X6vHGu04bZEM0eO35tNUkT_58vvFuTUDhRhG2cUJpw"];
        };
      };
    };
  };
}
