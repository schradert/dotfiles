{config, ...}: let
  inherit (config.canivete.deploy) nodes;
in {
  dotfiles = {canivete, config, lib, ...}: let
    inherit (config) domain root;
    inherit (lib) mkDefault mkEnableOption mkOption types mkMerge mkIf concatStringsSep optional flatten mkForce getExe optionalAttrs;
    # TODO dynamic
    url = "https://headscale.${domain}:8080";
  in {
    options.nodes = canivete.mkNestedSubmodule ({config, name, ...}: {
      opentofu = {pkgs, ...}: let
        inherit (nodes.${name}.profiles.system.canivete.configuration.config.dotfiles.services) headscale;
        secret_resources = ["shell_script.headscale_pre_auth_key-${name}" "shell_script.tailscale_k3s_auth-${name}"];
      in {
        module."nixos_${name}_system_install".depends_on = mkIf (!headscale.enable) secret_resources;
        resource = {
          # NOTE this is temporary while my headscale state broke...
          null_resource."nixos_${name}_system".depends_on = secret_resources;
          # null_resource."nixos_${name}_system".depends_on = mkIf headscale.enable secret_resources;
          # TODO maybe there's a way to create sops phases too usptream?
          # NOTE watch out for https://github.com/awlsring/terraform-provider-headscale/issues/11
          headscale_pre_auth_key.${name} = {
            user = "\${ headscale_user.main.name }";
            reusable = true;
          };
          # TODO combine these resources to avoid "Invalid reference from destroy provisioner"
          shell_script."headscale_pre_auth_key-${name}" = {
            triggers.key = "\${ headscale_pre_auth_key.${name}.key }";
            sensitive_environment.KEY = "\${ headscale_pre_auth_key.${name}.key }";
            lifecycle_commands = {
              create = "\${ local.SOPS_BIN } set \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"${name}\"][\"pre_auth_key\"]' \"\\\"$KEY\\\"\"";
              # TODO was it a problem this was set to api_key in --extract?
              read = ''
                ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["${name}"]["pre_auth_key"]' "''${ local.SOPS_DEFAULT }" |
                ${getExe pkgs.jq} --raw-input '{api_key:.}'
              '';
              delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"${name}\"][\"pre_auth_key\"]'";
            };
          };
          shell_script."tailscale_k3s_auth-${name}" = let
            key = "name=tailscale,joinKey=\${ headscale_pre_auth_key.${name}.key },controlServerURL=${url}";
          in {
            triggers.key = key;
            sensitive_environment.KEY = key;
            lifecycle_commands = {
              create = "\${ local.SOPS_BIN } set \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"${name}\"][\"k3s_auth\"]' \"\\\"$KEY\\\"\"";
              read = ''
                ''${ local.SOPS_BIN } --decrypt --extract '["tailscale"]["${name}"]["k3s_auth"]' "''${ local.SOPS_DEFAULT }" |
                ${getExe pkgs.jq} --raw-input '{k3s_auth:.}'
              '';
              delete = "\${ local.SOPS_BIN } unset \"\${ local.SOPS_DEFAULT }\" '[\"tailscale\"][\"${name}\"][\"k3s_auth\"]'";
            };
          };
        };
      };
    });
    config.nixos = {
      config,
      flake,
      lib,
      node,
      pkgs,
      ...
    }: let
      inherit (config.dotfiles) tailscale;
    in {
      options.dotfiles.tailscale = {
        enable = mkEnableOption "Tailscale daemon" // {default = true;};
        interface = canivete.mkNullableOption types.str {description = "External interface for tailscale node";};
        routes = canivete.mkArgsOption {description = "Subnet routes to advertise";};
      };
      config = mkIf tailscale.enable {
        # canivete.kubernetes.k3s.vpn-auth-file = config.sops.secrets."tailscale/${node.name}/k3s_auth".path;
        # networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];
        services.cloud-init.enable = false;
        services.k3s.extraFlags = mkMerge [
          # ["--node-external-ip=$$(tailscale ip --4)"]
          # ["--node-ip=$$(tailscale ip --4)"]
          # (mkIf (tailscale.interface != null) [
            # "--node-external-ip=$$(ip -family inet -json addr show scope global dev ${tailscale.interface} | jq --raw-output '.[0].addr_info[0].local')"
          # ])
        ];
        services.tailscale = {
          enable = true;
          openFirewall = true;
          authKeyFile = config.sops.secrets."tailscale/${node.name}/pre_auth_key".path;
          extraUpFlags = ["--login-server" url];
          extraSetFlags = ["--advertise-routes" (concatStringsSep "," tailscale.routes)];
          useRoutingFeatures = mkDefault (if config.dotfiles.profiles.server.enable then "both" else "client");
        };
        sops.secrets."tailscale/${node.name}/k3s_auth" = {};
        sops.secrets."tailscale/${node.name}/pre_auth_key" = {};
        systemd.services.k3s = {
          # NOTE for some reason I still have to use path instead of providing an absolute path above...
          path = [config.services.tailscale.package pkgs.iproute2 pkgs.jq];
          # requires = ["tailscaled-autoconnect.service"];
          serviceConfig.ExecStart = let
            # NOTE ALL OF THIS HAD TO BE COPIED FROM UPSTREAM TO OVERRIDE... don't get me started on why
            cfg = config.services.k3s;
            kubeletParams =
              (optionalAttrs cfg.gracefulNodeShutdown.enable {
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
            command = concatStringsSep " \\\n " (
              ["${cfg.package}/bin/k3s ${cfg.role}"]
              ++ (optional cfg.clusterInit "--cluster-init")
              ++ (optional cfg.disableAgent "--disable-agent")
              ++ (optional (cfg.serverAddr != "") "--server ${cfg.serverAddr}")
              ++ (optional (cfg.token != "") "--token ${cfg.token}")
              ++ (optional (cfg.tokenFile != null) "--token-file ${cfg.tokenFile}")
              ++ (optional (cfg.configPath != null) "--config ${cfg.configPath}")
              ++ (optional (kubeletParams != {}) "--kubelet-arg=config=${kubeletConfig}")
              ++ (optional (cfg.extraKubeProxyConfig != {}) "--kube-proxy-arg=config=${kubeProxyConfig}")
              ++ (flatten cfg.extraFlags)
            );
          in
            mkForce "${getExe pkgs.bash} -c '${command}'";
        };
        # systemd.services.tailscaled-autoconnect.requires = ["sops-install-secrets.service"];
      };
    };
  };
}
