{config, ...}: let
  inherit (config.canivete.meta.people.my.profiles.default) email;
in {
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["^.+/dns-query$"];
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (canivete) mkNullableOption;
    inherit (config) domain services;
    inherit (services.cert-manager) enable provider;
    inherit (lib) concatStringsSep replaceStrings toList mkIf mkEnableOption mkMerge mkOption types;
    inherit (types) attrTag str submodule;
    finalImageTag = "v1.18.2";
    images = {
      cert-manager-cainjector = {
        imageName = "quay.io/jetstack/cert-manager-cainjector";
        imageDigest = "sha256:af59e01ad9756a1034fbf948330e75702e5d79b3577f323f6a9947707ba262fc";
        hash = "sha256-djL8juN3DAWfGK7Xckzhi2lVOmjWsbI+ftdR9VDgU8M=";
        inherit finalImageTag;
      };
      cert-manager-controller = {
        imageName = "quay.io/jetstack/cert-manager-controller";
        imageDigest = "sha256:81316365dc0b713eddddfbf9b8907b2939676e6c0e12beec0f9625f202a36d16";
        hash = "sha256-wjkd5bxv8Wyc2XoAnyChGUpUh3HZ/0hTsmzQM9CFT6E=";
        inherit finalImageTag;
      };
      cert-manager-startupapicheck = {
        imageName = "quay.io/jetstack/cert-manager-startupapicheck";
        imageDigest = "sha256:1075e097415167caa584b203292dfb57e46866df0adb76fe769ef5cb0297ccc4";
        hash = "sha256-J2Jknmpiem4fAXot8SC18SNo1LxR6zZAQerSXjOCVXY=";
        inherit finalImageTag;
      };
      cert-manager-webhook = {
        imageName = "quay.io/jetstack/cert-manager-webhook";
        imageDigest = "sha256:9431f0d8b5103b06cc6138564f471ac02c6b2638c2fa399d81e28a01d817ae73";
        hash = "sha256-biaH9XrU5WLPDkBZ/QKTCBbEFLRHvhs5+KnBoquOhFQ=";
        inherit finalImageTag;
      };
      cert-manager-acmesolver = {
        imageName = "quay.io/jetstack/cert-manager-acmesolver";
        imageDigest = "sha256:1c81a771e3e3a210466aa25f5fc05ce5c286e0eb90d96563cc0275aaa50788c2";
        hash = "sha256-POf/KuSY6IQPtJwjpl/3sZaA48zRopc3aXJaCK5RXZQ=";
        inherit finalImageTag;
      };
    };
  in {
    options.services.cert-manager = {
      enable = mkEnableOption "cert-manager";
      provider = mkOption {
        description = "Configuration for specific providers";
        type = attrTag {
          google = mkOption {
            description = "Google cert-manager configuration";
            type = submodule {
              options.project = mkNullableOption str {description = "Google project with DNS service enabled";};
              options.credentials = mkNullableOption str {description = "Contents of service account credentials (supports vals)";};
            };
          };
          cloudflare = mkOption {
            description = "Cloudflare cert-manager configuration";
            type = submodule {
              options.token = mkNullableOption str {description = "Secret personal API token (supports vals)";};
            };
          };
        };
      };
    };
    config = mkIf enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      home-manager = {
        config,
        pkgs,
        systemConfiguration,
        ...
      }: {
        config = mkIf (config.dotfiles.profiles.client.workstation.enable || systemConfiguration.config.canivete.kubernetes.enable) {
          home.packages = [pkgs.cmctl];
          # programs.k9s.plugin.plugins = let
          #   bash = getExe pkgs.bash;
          #   cmctl = getExe pkgs.cmctl;
          #   less = getExe pkgs.less;
          # in {
          #   cert-status = {
          #     shortCut = "Shift-S";
          #     description = "Certificate status";
          #     scopes = ["certificates"];
          #     confirm = false;
          #     background = false;
          #     command = bash;
          #     args = ["-c" "${cmctl} status certificate --context $CONTEXT --namespace $NAMESPACE $NAME |& ${less}"];
          #   };
          #   cert-renew = {
          #     shortCut = "Shift-R";
          #     description = "Certificate renew";
          #     scopes = ["certificates"];
          #     confirm = true;
          #     background = false;
          #     command = bash;
          #     args = ["-c" "${cmctl} renew --context $CONTEXT --namespace $NAMESPACE $NAME |& ${less}"];
          #   };
          #   # TODO get secret from a certificate!
          # };
        };
      };
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        dotfiles.crds.cert-manager = {
          prefix = "deploy/crds";
          src = pkgs.fetchFromGitHub {
            owner = "cert-manager";
            repo = "cert-manager";
            rev = finalImageTag;
            hash = "sha256-BGUStT8rEgy/hBTgUAnifaq+Pa5T1VT63LNUaQySOQs=";
          };
        };
        applications.cert-manager = {
          namespace = "security";
          helm.releases.cert-manager = {
            chart = charts.jetstack.cert-manager;
            values = {
              crds.enabled = true;
              dns01RecursiveNameservers = concatStringsSep "," ["https://1.1.1.1:443/dns-query" "https://1.0.0.1:443/dns-query"];
              dns01RecursiveNameserversOnly = true;
              prometheus.enabled = true;
              prometheus.servicemonitor.enabled = services.prometheus.enable;

              image = {
                repository = images.cert-manager-controller.imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
              cainjector.image = {
                repository = images.cert-manager-cainjector.imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
              startupapicheck.image = {
                repository = images.cert-manager-startupapicheck.imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
              webhook.image = {
                repository = images.cert-manager-webhook.imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
              acmesolver.image = {
                repository = images.cert-manager-acmesolver.imageName;
                tag = finalImageTag;
                pullPolicy = "Never";
              };
            };
          };
          resources = let
            domainName = replaceStrings ["."] ["-"] domain;
            mkClusterIssuer = name: server: {
              spec.acme = {
                inherit server email;
                privateKeySecretRef = {inherit name;};
                solvers = toList (mkMerge [
                  {selector.dnsZones = [domain];}
                  (mkIf (provider ? google) {
                    dns01.cloudDNS = {
                      inherit (provider.google) project;
                      serviceAccountSecretRef = {
                        name = "cert-manager";
                        key = "credentials";
                      };
                    };
                  })
                  (mkIf (provider ? cloudflare) {
                    dns01.cloudflare.apiTokenSecretRef = {
                      name = "cert-manager";
                      key = "credentials";
                    };
                  })
                ]);
              };
            };
          in {
            externalSecrets.cert-manager.spec = {
              secretStoreRef.name = "bitwarden";
              secretStoreRef.kind = "ClusterSecretStore";
              data = toList {
                secretKey = "credentials";
                remoteRef.key = mkMerge [
                  (mkIf (provider ? google) provider.google.token)
                  (mkIf (provider ? cloudflare) provider.cloudflare.token)
                ];
              };
            };
            clusterIssuers.letsencrypt-production = mkClusterIssuer "letsencrypt-production" "https://acme-v02.api.letsencrypt.org/directory";
            clusterIssuers.letsencrypt-staging = mkClusterIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
            certificates.${domainName}.spec = {
              secretName = "${domainName}-tls";
              issuerRef.name = "letsencrypt-staging";
              issuerRef.kind = "ClusterIssuer";
              commonName = domain;
              dnsNames = [domain "*.${domain}"];
            };
          };
        };
      };
    };
  };
}
