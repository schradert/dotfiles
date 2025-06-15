{
  dotfiles = {config, lib, ...}: let
    inherit (config) domain;
    inherit (lib) getExe;
    # TODO will this behave normally?
    port = 80;
    hostname = "headscale.${domain}";
    url = "https://${hostname}:${builtins.toString port}";
  in {
    opentofu = {
      plugins = ["awlsring/headscale" "opentofu/time" "linyinfeng/shell"];
      modules = {pkgs, ...}: {
        # Refresh Headscale API Key
        resource.time_rotating.headscale_api_key.rotation_days = 90;
        resource.shell_script.headscale_api_key = {
          depends_on = ["module.nixos_bootstrap_system_install"];
          # TODO how can I trigger this when bootstrap is redeployed?
          # triggers.install = "\${ module.nixos_bootstrap_system_install.null_resource.nixos-remote.id }";
          triggers.expiration = "\${ time_rotating.headscale_api_key.id }";
          lifecycle_commands = {
            # TODO do I have to wait until bootstrap is available?
            # NOTE might be why I have to apply this TWICE!?
            # FIXME correct ssh connection
            create = ''
              ssh bootstrap headscale apikeys create --output json-line |
                xargs -I{} ''${ local.SOPS_BIN } set "''${ local.SOPS_DEFAULT }" '["tailscale"]["api_key"]' "\"{}\""
            '';
            read = ''
              ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["api_key"]' "''${ local.SOPS_DEFAULT }" |
                ${getExe pkgs.jq} --raw-input '{api_key:.}'
            '';
            delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"api_key\"]'";
          };
        };

        # Headscale basics
        provider.headscale.endpoint = url;
        provider.headscale.api_key = "\${ shell_script.headscale_api_key.output.api_key }";
        resource.headscale_user.main = {
          depends_on = ["google_dns_record_set.headscale-a"];
          name = "main";
          force_delete = true;
        };
      };
    };
    nixos = {config, flake, pkgs, ...}: let
      inherit (config.dotfiles.services) headscale;
      inherit (lib) mkDefault mkEnableOption mkIf mkOption;
      json = pkgs.formats.json {};
    in {
      options.dotfiles.services.headscale = {
        enable = mkEnableOption "Headscale control server";
        policy = mkOption {
          inherit (json) type;
          default = {};
          description = "Contents of policy document";
        };
      };
      config = mkIf config.dotfiles.services.headscale.enable {
        dotfiles.services.headscale.policy = {
          acls = mkDefault [
            {
              action = "accept";
              src = ["*"];
              dst = ["*:*"];
            }
          ];
          autoApprovers.routes."10.0.0.0/8" = ["main"];
        };
        nixpkgs.overlays = [flake.inputs.headscale.overlay];
        # NOTE https://tailscale.com/kb/1082/firewall-ports
        networking.firewall.allowedUDPPorts = [3478];
        networking.firewall.allowedTCPPorts = [port];
        services.headscale = {
          enable = true;
          address = "0.0.0.0";
          inherit port;
          settings = {
            # TODO how can I prevent this long string?
            acme_email = flake.config.canivete.meta.people.my.profiles.default.email;
            # TODO why do staging certificates not even work?
            # acme_url = "https://acme-staging-v02.api.letsencrypt.org/directory";
            tls_letsencrypt_hostname = hostname;
            tls_letsencrypt_listen = ":${builtins.toString port}";
            server_url = url;
            dns.base_domain = "tailscale.${domain}";
            log.level = "debug";
            policy.path = json.generate "headscale.json" headscale.policy;
          };
        };
      };
    };
  };
}
