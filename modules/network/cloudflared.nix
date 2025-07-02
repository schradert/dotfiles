{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkIf mkEnableOption mkMerge toList recursiveUpdate;
    inherit (config) domain services;
    image = {
      imageName = "docker.io/cloudflare/cloudflared";
      imageDigest = "sha256:09598b52370639bc74daa2faf78731e0922af686f7fb0a6415c6d5c8f0f003b1";
      hash = "sha256-asDmVbmBZzNHVIHgrXY/8f5ozC4VdB5CnuUiHxhaa0U=";
      finalImageTag = "2025.6.1";
    };
  in {
    options.services.cloudflared.enable = mkEnableOption "Cloudflared Tunnel";
    config = mkIf services.cloudflared.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images.cloudflared = pkgs.dockerTools.pullImage image;};
      opentofu.sops = {
        cloudflare-tunnel-token.value = "\${ data.cloudflare_zero_trust_tunnel_cloudflared_token.main.token }";
        cloudflare-tunnel-token.path = ["cloudflare" "tunnel" "token"];
        cloudflare-tunnel-id.value = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.id }";
        cloudflare-tunnel-id.path = ["cloudflare" "tunnel" "id"];
      };
      opentofu.modules = {
        resource.cloudflare_zero_trust_tunnel_cloudflared.main = {
          account_id = "\${ data.cloudflare_accounts.main.result[0].id }";
          name = "main";
          config_src = "local";
        };
        data.cloudflare_zero_trust_tunnel_cloudflared_token.main = {
          account_id = "\${ data.cloudflare_accounts.main.result[0].id }";
          tunnel_id = "\${ cloudflare_zero_trust_tunnel_cloudflared.main.id }";
        };
      };
      nixidy = {
        canivete,
        charts,
        ...
      }: let
        inherit (canivete.vals.sops) default;
        subdomain = "external.${domain}";
        gateway = "https://cilium-gateway-external.kube-system.svc.cluster.local";
        credsPath = "/etc/cloudflared/token.txt";
        configPath = "/etc/cloudflared/config.yaml";
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
        applications.cloudflared = {
          namespace = "kube-system";
          resources."externaldns.k8s.io".v1alpha1.DNSEndpoint.cloudflared-tunnel.spec.endpoints = toList {
            dnsName = subdomain;
            recordType = "CNAME";
            targets = ["${default "cloudflare/tunnel/id"}.cfargotunnel.com"];
          };
          helm.releases.cloudflared = {
            chart = charts.bjw-s-labs.app-template;
            values = mkMerge [
              {
                secrets.cloudflared.stringData."token.txt" = default "cloudflare/tunnel/token";
                configMaps.cloudflared.data."config.yaml" = builtins.toJSON {
                  tunnel = default "cloudflare/tunnel/id";
                  token-file = credsPath;
                  no-autoupdate = true;
                  metrics = "0.0.0.0:8080";
                  originRequest.originServerName = subdomain;
                  ingress = [
                    {
                      hostname = domain;
                      service = gateway;
                    }
                    {
                      hostname = "*.${domain}";
                      service = gateway;
                    }
                    {service = "http_status:404";}
                  ];
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
                    image.repository = image.imageName;
                    image.tag = image.finalImageTag;
                    args = ["tunnel" "--config" configPath "run"];
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
                    subPath = "token.txt";
                    readOnly = true;
                  };
                };
              }
              (mkIf services.prometheus.enable {
                serviceMonitor.cloudflared.serviceName = "cloudflared";
                serviceMonitor.cloudflared.endpoints = toList {
                  port = "http";
                  scheme = "http";
                  path = "/metrics";
                  interval = "1m";
                  scrapeTimeout = "30s";
                };
              })
            ];
          };
        };
      };
      kubenix = {canivete, ...}: let
        inherit (canivete.vals.sops) default;
        subdomain = "external.${domain}";
        gateway = "https://cilium-gateway-external.kube-system.svc.cluster.local";
        credsPath = "/etc/cloudflared/token.txt";
        configPath = "/etc/cloudflared/config.yaml";
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
          namespace = "kube-system";
          extraResources.dnsendpoints.cloudflared-tunnel.spec.endpoints = toList {
            dnsName = subdomain;
            recordType = "CNAME";
            targets = ["${default "cloudflare/tunnel/id"}.cfargotunnel.com"];
          };
          values = mkMerge [
            {
              secrets.cloudflared.stringData."token.txt" = default "cloudflare/tunnel/token";
              configMaps.cloudflared.data."config.yaml" = builtins.toJSON {
                tunnel = default "cloudflare/tunnel/id";
                token-file = credsPath;
                no-autoupdate = true;
                metrics = "0.0.0.0:8080";
                originRequest.originServerName = subdomain;
                ingress = [
                  {
                    hostname = domain;
                    service = gateway;
                  }
                  {
                    hostname = "*.${domain}";
                    service = gateway;
                  }
                  {service = "http_status:404";}
                ];
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
                  image.repository = image.imageName;
                  image.tag = image.finalImageTag;
                  args = ["tunnel" "--config" configPath "run"];
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
                  subPath = "token.txt";
                  readOnly = true;
                };
              };
            }
            (mkIf services.prometheus.enable {
              serviceMonitor.cloudflared.serviceName = "cloudflared";
              serviceMonitor.cloudflared.endpoints = toList {
                port = "http";
                scheme = "http";
                path = "/metrics";
                interval = "1m";
                scrapeTimeout = "30s";
              };
            })
          ];
        };
      };
    };
  };
}
