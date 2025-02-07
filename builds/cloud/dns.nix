{
  canivete,
  config,
  ...
}: let
  inherit (canivete.vals) sops;
  inherit (config.dotfiles) domain;
  inherit (config.canivete.people.my.profiles.default) email;
in {
  perSystem.canivete.opentofu.workspaces.deploy = {
    plugins = ["cloudflare/cloudflare/4.43.0"];
    modules.dns = {
      provider.cloudflare.api_token = sops "default.yaml#/cloudflare/pat";
      data.cloudflare_accounts.main.name = email;
      resource = {
        cloudflare_zone.trdos = {
          account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
          zone = domain;
        };
        cloudflare_record.base = {
          name = "@";
          content = sops "default.yaml#/trdos_ip";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
        cloudflare_record.www = {
          name = "www";
          content = "\${ cloudflare_zone.trdos.zone }";
          type = "CNAME";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
        cloudflare_record.wildcard = {
          name = "*";
          content = sops "default.yaml#/trdos_ip";
          type = "A";
          zone_id = "\${ cloudflare_zone.trdos.id }";
        };
      };
    };
  };
}
