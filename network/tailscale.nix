{config, ...}: let
  inherit (config.canivete.meta) domain root;
  subdomain = "headscale";
  port = 8080;
  acme_port = 8081;
  hostname = "${subdomain}.${domain}";
  url = "https://${hostname}:${toString port}";
in {
  dotfiles.nixos = {
    config,
    flake,
    lib,
    node,
    pkgs,
    ...
  }: {
    options.dotfiles.tailscale.enable = lib.mkEnableOption "Tailscale server" // {default = true;};
    config = lib.mkMerge [
      (lib.mkIf (node.name == root) {
        nixpkgs.overlays = [flake.inputs.headscale.overlay];
        # NOTE https://tailscale.com/kb/1082/firewall-ports
        networking.firewall.allowedUDPPorts = [3478];
        networking.firewall.allowedTCPPorts = [port acme_port];
        # LetsEncrypt only calls port 80 so we need something to forward temporarily
        networking.firewall.extraCommands = "iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port ${toString acme_port}";
        # services.cloud-init.enable = lib.mkForce false;
        # systemd.services.headscale.serviceConfig = {
        #   AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
        #   CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        # };
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
            tls_letsencrypt_listen = ":${toString acme_port}";
            server_url = url;
            dns.base_domain = "tailscale.${domain}";
            log.level = "debug";
            policy.path = (pkgs.formats.json {}).generate "headscale.json" {
              acls = [
                {
                  action = "accept";
                  src = ["*"];
                  dst = ["*:*"];
                }
              ];
              autoApprovers.routes."10.0.0.0/8" = ["main"];
            };
          };
        };
      })
      (lib.mkIf config.dotfiles.tailscale.enable {
        canivete.kubernetes.k3s.vpn-auth-file = config.sops.secrets."tailscale/k3s_auth".path;
        networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];
        services.cloud-init.enable = false;
        services.k3s.extraFlags = [
          "--node-ip=$$(tailscale ip --4)"
          "--node-external-ip=$$(ip -family inet -json addr show scope global dev eth0 | jq --raw-output '.[0].addr_info[0].local')"
        ];
        services.tailscale = {
          enable = true;
          openFirewall = true;
          authKeyFile = config.sops.secrets."tailscale/pre_auth_key".path;
          extraUpFlags = ["--login-server" url "--advertise-routes" "10.0.0.0/8"];
          useRoutingFeatures = "client";
        };
        sops.secrets."tailscale/k3s_auth" = {};
        sops.secrets."tailscale/pre_auth_key" = {};
        systemd.services.k3s = {
          # NOTE for some reason I still have to use path instead of providing an absolute path above...
          path = [config.services.tailscale.package pkgs.iproute2 pkgs.jq];
          requires = ["tailscaled-autoconnect.service"];
          serviceConfig.ExecStart = let
            # NOTE ALL OF THIS HAD TO BE COPIED FROM UPSTREAM TO OVERRIDE... don't get me started on why
            cfg = config.services.k3s;
            kubeletParams =
              (lib.optionalAttrs cfg.gracefulNodeShutdown.enable {
                inherit (cfg.gracefulNodeShutdown) shutdownGracePeriod shutdownGracePeriodCriticalPods;
              })
              // cfg.extraKubeletConfig;
            kubeletConfig = (pkgs.formats.yaml {}).generate "k3s-kubelet-config" (
              {
                apiVersion = "kubelet.config.k8s.io/v1beta1";
                kind = "KubeletConfiguration";
              }
              // kubeletParams
            );
            kubeProxyConfig = (pkgs.formats.yaml {}).generate "k3s-kubeProxy-config" (
              {
                apiVersion = "kubeproxy.config.k8s.io/v1alpha1";
                kind = "KubeProxyConfiguration";
              }
              // cfg.extraKubeProxyConfig
            );
            command = lib.concatStringsSep " \\\n " (
              ["${cfg.package}/bin/k3s ${cfg.role}"]
              ++ (lib.optional cfg.clusterInit "--cluster-init")
              ++ (lib.optional cfg.disableAgent "--disable-agent")
              ++ (lib.optional (cfg.serverAddr != "") "--server ${cfg.serverAddr}")
              ++ (lib.optional (cfg.token != "") "--token ${cfg.token}")
              ++ (lib.optional (cfg.tokenFile != null) "--token-file ${cfg.tokenFile}")
              ++ (lib.optional (cfg.configPath != null) "--config ${cfg.configPath}")
              ++ (lib.optional (kubeletParams != {}) "--kubelet-arg=config=${kubeletConfig}")
              ++ (lib.optional (cfg.extraKubeProxyConfig != {}) "--kube-proxy-arg=config=${kubeProxyConfig}")
              ++ (lib.flatten cfg.extraFlags)
            );
          in
            lib.mkForce "${lib.getExe pkgs.bash} -c '${command}'";
        };
        systemd.services.tailscaled-autoconnect.requires = ["sops-install-secrets.service"];
      })
    ];
  };
  dotfiles.opentofu = {
    plugins = ["awlsring/headscale" "hashicorp/time" "linyinfeng/shell"];
    modules = {
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) getExe;
    in {
      resource.google_dns_record_set.headscale-a = {
        name = "${subdomain}.\${ google_dns_managed_zone.main.dns_name }";
        managed_zone = "\${ google_dns_managed_zone.main.name }";
        type = "A";
        ttl = 240;
        rrdatas = ["\${ local.root_ip }"];
      };
      resource.google_dns_record_set.wildcard-headscale-a = {
        name = "*.${subdomain}.\${ google_dns_managed_zone.main.dns_name }";
        managed_zone = "\${ google_dns_managed_zone.main.name }";
        type = "A";
        ttl = 240;
        rrdatas = ["\${ local.root_ip }"];
      };
      provider.shell.interpreter = [(getExe pkgs.bash) "-c"];
      resource.time_rotating.headscale_api_key.rotation_days = 90;
      # TODO should I do something similar for hcloud and gcloud?
      resource.shell_script.headscale_api_key = {
        depends_on = ["module.nixos_${root}_system_install"];
        # TODO how can I trigger this when root is redeployed?
        # triggers.install = "\${ module.nixos_${root}_system_install.null_resource.nixos-remote.id }";
        triggers.expiration = "\${ time_rotating.headscale_api_key.id }";
        lifecycle_commands = {
          # TODO do I have to wait until root is available?
          # NOTE might be why I have to apply this TWICE!?
          create = ''
            ssh root@${root}.vpn.${domain} headscale apikeys create --output json-line |
              xargs -I{} ''${ local.SOPS_BIN } set "''${ local.SOPS_DEFAULT }" '["tailscale"]["api_key"]' "\"{}\""
          '';
          read = ''
            ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["api_key"]' "''${ local.SOPS_DEFAULT }" |
              ${getExe pkgs.jq} --raw-input '{api_key:.}'
          '';
          delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"api_key\"]'";
        };
      };
      provider.headscale.endpoint = url;
      provider.headscale.api_key = "\${ shell_script.headscale_api_key.output.api_key }";
      resource.headscale_user.main = {
        depends_on = ["google_dns_record_set.headscale-a"];
        name = "main";
        force_delete = true;
      };
      # TODO maybe there's a way to create sops phases too usptream?
      resource.headscale_pre_auth_key.main = {
        user = "\${ headscale_user.main.name }";
        reusable = true;
      };
      # TODO combine these resources
      # Avoid "Invalid reference from destroy provisioner"
      resource.shell_script.headscale_pre_auth_key-main = {
        triggers.key = "\${ headscale_pre_auth_key.main.key }";
        sensitive_environment.KEY = "\${ headscale_pre_auth_key.main.key }";
        lifecycle_commands = {
          create = "\${ local.SOPS_BIN } set \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"pre_auth_key\"]' \"\\\"$KEY\\\"\"";
          # TODO was it a problem this was set to api_key in --extract?
          read = ''
            ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["pre_auth_key"]' "''${ local.SOPS_DEFAULT }" |
            ${getExe pkgs.jq} --raw-input '{api_key:.}'
          '';
          delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"pre_auth_key\"]'";
        };
      };
      resource.shell_script.tailscale_k3s_auth = let
        key = "name=tailscale,joinKey=\${ headscale_pre_auth_key.main.key },controlServerURL=${url}";
      in {
        triggers.key = key;
        sensitive_environment.KEY = key;
        lifecycle_commands = {
          create = "\${ local.SOPS_BIN } set \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"k3s_auth\"]' \"\\\"$KEY\\\"\"";
          read = ''
            ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["k3s_auth"]' "''${ local.SOPS_DEFAULT }" |
            ${getExe pkgs.jq} --raw-input '{k3s_auth:.}'
          '';
          delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"k3s_auth\"]'";
        };
      };
      resource.null_resource."nixos_${root}_system".depends_on = ["shell_script.headscale_pre_auth_key-main" "shell_script.tailscale_k3s_auth"];
    };
  };
}
