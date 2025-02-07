{
  canivete,
  config,
  lib,
  ...
}: let
  inherit (canivete) vals;
  inherit (lib) toList recursiveUpdate;
  inherit (config.dotfiles) domain;
  inherit (config.canivete) root;
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
  perSystem.canivete.opentofu.workspaces.deploy.modules.cloudflared.resource.cloudflare_zero_trust_tunnel_cloudflared.main = {
    account_id = "\${ data.cloudflare_accounts.main.accounts[0].id }";
    name = "main";
    secret = "\${ base64encode(random_password.cloudflare-tunnel-secret.result) }";
    config_src = "local";
  };
  perSystem.dotfiles.opentofu = {
    passwords.cloudflare-tunnel-secret.length = 21;
    sops = {
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
  };
  perSystem.dotfiles.helm.cloudflared = {
    namespace = "network";
    values = {
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
            {secret = "cloudflared-secret";}
            {configMapRef.name = "cloudflared-configmap";}
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
        name = "cloudflared-configmap";
        globalMounts = toList {
          path = configPath;
          subPath = "config.yaml";
          readOnly = true;
        };
      };
      persistence.creds = {
        type = "secret";
        name = "cloudflared-secret";
        globalMounts = toList {
          path = credsPath;
          subPath = "credentials.json";
          readOnly = true;
        };
      };
    };
    resources.dnsendpoints.cloudflared-tunnel.spec.endpoints = toList {
      dnsName = subdomain;
      recordType = "CNAME";
      targets = [(vals.sops "default.yaml#/cloudflare/tunnel/cname")];
    };
    resources.secrets.cloudflared-secret.stringData = {
      TUNNEL_ID = vals.sops "default.yaml#/cloudflare/tunnel/id";
      "credentials.json" = builtins.toJSON {
        AccountTag = vals.sops "default.yaml#/cloudflare/account_id";
        TunnelSecret = vals.sops "default.yaml#/cloudflare/tunnel/secret";
        TunnelID = vals.sops "default.yaml#/cloudflare/tunnel/id";
      };
    };
    resources.configMaps.cloudflared-configmap.data = {
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
  };
}
