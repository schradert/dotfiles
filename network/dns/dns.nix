{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete.vals) sops;
  inherit (config.canivete.meta) domain root people;
  inherit (people.my.profiles.default) email;
in {
  dotfiles = {
    # TODO is there a better place to keep fetchKubeconfig?
    # NOTE cannot split this into multiline because it is injected into a script
    kubenix.canivete.deploy.fetchKubeconfig = "ssh root@${root} k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${domain}/g'";
    nixos.canivete.kubernetes.k3s.tls-san = lib.mkForce ["${domain}"];
    opentofu.plugins = ["cloudflare/cloudflare/4.43.0"];
    opentofu.modules = {
      provider.cloudflare.api_token = sops.default "cloudflare/pat";
      data.cloudflare_accounts.main.name = email;
      resource = {
        cloudflare_zone.trdos = {
          account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
          zone = domain;
        };
        cloudflare_record = {
          root-a = {
            name = "@";
            content = sops.default "trdos_ip";
            type = "A";
            zone_id = "\${ cloudflare_zone.trdos.id }";
          };
          www-c = {
            name = "www";
            content = "\${ cloudflare_zone.trdos.zone }";
            type = "CNAME";
            zone_id = "\${ cloudflare_zone.trdos.id }";
          };
          wildcard = {
            name = "*";
            content = sops.default "trdos_ip";
            type = "A";
            zone_id = "\${ cloudflare_zone.trdos.id }";
          };
        };
      };
    };
  };
}
