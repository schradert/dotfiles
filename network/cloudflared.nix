{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mapAttrs mkIf mkEnableOption toList recursiveUpdate;
    inherit (config) domain root services;
  in {
    options.services.cloudflared.enable = mkEnableOption "Cloudflared Tunnel";
    config = mkIf services.cloudflared.enable {
      opentofu.passwords.cloudflare-tunnel-secret.length = 21;
      opentofu.sops = {
        cloudflare-account-id.value = "\${ data.cloudflare_accounts.main.accounts[0].id }";
        cloudflare-account-id.path = ["cloudflare" "account_id"];
        cloudflare-tunnel-cname.value = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.cname }";
        cloudflare-tunnel-cname.path = ["cloudflare" "tunnel" "cname"];
        cloudflare-tunnel-token.value = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.tunnel_token }";
        cloudflare-tunnel-token.path = ["cloudflare" "tunnel" "token"];
        cloudflare-tunnel-id.value = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.id }";
        cloudflare-tunnel-id.path = ["cloudflare" "tunnel" "id"];
        cloudflare-tunnel-secret-base64.value = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.secret }";
        cloudflare-tunnel-secret-base64.path = ["cloudflare" "tunnel" "secret"];
      };
      opentofu.modules.resource.cloudflare_zero_trust_tunnel_cloudflared.main = {
        account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
        name = "main";
        secret = "\${ base64encode(random_password.cloudflare-tunnel-secret.result) }";
        config_src = "local";
      };
      kubenix = {canivete, ...}: let
        inherit (canivete.vals.sops) default;
        subdomain = "external.${domain}";
        credsPath = "/etc/cloudflared/creds/credentials.json";
        configPath = "/etc/cloudflared/config/config.yaml";
        port = 8080;
        probe = {
          enabled = true;
          custom = true;
          spec = {
            httpGet.path = "/ready";
            httpGet.port = port;
            initialDelaySeconds = 0;
            periodSeconds = 10;
            timeoutSeconds = 1;
            failureThreshold = 3;
          };
        };
      in {
        kubernetes.helm.releases.cloudflared = {
          namespace = "network";
          extraResources.dnsendpoints.cloudflared-tunnel.spec.endpoints = toList {
            dnsName = subdomain;
            recordType = "CNAME";
            targets = [(default "cloudflare/tunnel/cname")];
          };
          values = {
            secrets.cloudflared.data = mapAttrs (_: canivete.toBase64) {
              TUNNEL_ID = default "cloudflare/tunnel/id";
              "credentials.json" = builtins.toJSON {
                AccountTag = default "cloudflare/account_id";
                TunnelSecret = default "cloudflare/tunnel/secret";
                TunnelID = default "cloudflare/tunnel/id";
              };
            };
            configMaps.cloudflared.data = {
              NO_AUTOUPDATE = "true";
              TUNNEL_CRED_FILE = credsPath;
              TUNNEL_METRICS = "0.0.0.0:8080";
              "config.yaml" = builtins.toJSON {
                originRequest.originServerName = subdomain;
                ingress = [
                  {
                    hostname = domain;
                    service = "https://nginx-external-controller.network.svc.cluster.local:443";
                  }
                  {
                    hostname = domain;
                    service = "ssh://${root}:22";
                  }
                  {
                    hostname = "*.${domain}";
                    service = "https://nginx-external-controller.network.svc.cluster.local:443";
                  }
                  {service = "http_status:404";}
                ];
              };
            };
            controllers.cloudflared = {
              replicas = 2;
              strategy = "RollingUpdate";
              annotations."reloader.stakater.com/auto" = "true";
              pod.topologySpreadConstraints = toList {
                maxSkew = 1;
                topologyKey = "kubernetes.io/hostname";
                whenUnsatisfiable = "DoNotSchedule";
                labelSelector.matchLabels."app.kubernetes.io/name" = "cloudflared";
              };
              containers.cloudflared = {
                image.repository = "docker.io/cloudflare/cloudflared";
                image.tag = "2024.9.1";
                args = ["tunnel" "--config" configPath "run" "$(TUNNEL_ID)"];
                envFrom = [
                  {secret = "cloudflared";}
                  {configMapRef.name = "cloudflared";}
                ];
                probes.liveness = probe;
                probes.readiness = probe;
                probes.startup = recursiveUpdate probe {spec.failureThreshold = 30;};
                resources.requests.cpu = "10m";
                resources.requests.memory = "128Mi";
                resources.limits.memory = "256Mi";
              };
            };
            service.cloudflared.controller = "cloudflared";
            service.cloudflared.ports.http.port = port;
            serviceMonitor.cloudflared.serviceName = "cloudflared";
            serviceMonitor.cloudflared.endpoints = toList {
              port = "http";
              scheme = "http";
              path = "/metrics";
              interval = "1m";
              scrapeTimeout = "30s";
            };
            persistence.config = {
              type = "configMap";
              name = "cloudflared";
              globalMounts = toList {
                path = configPath;
                subPath = "config.yaml";
                readOnly = true;
              };
            };
            persistence.creds = {
              type = "secret";
              name = "cloudflared";
              globalMounts = toList {
                path = credsPath;
                subPath = "credentials.json";
                readOnly = true;
              };
            };
          };
        };
      };
    };
  };
}
