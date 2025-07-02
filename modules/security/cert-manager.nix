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
    inherit (canivete) mkNullableOption toBase64;
    inherit (config) domain services;
    inherit (services.cert-manager) enable provider;
    inherit (lib) concatStringsSep replaceStrings toList mkIf mkEnableOption mkMerge mkOption types;
    inherit (types) attrTag str submodule;
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
      nixos = {pkgs, ...}: let
        inherit (pkgs.dockerTools) pullImage;
      in {
        canivete.kubernetes.images = {
          cert-manager-cainjector = pullImage {
            imageName = "quay.io/jetstack/cert-manager-cainjector";
            imageDigest = "sha256:a8319ee78e94abb11c4fe0b35197a57848ae7eec6c526e369187dc57b2961116";
            hash = "sha256-7/ZPslP/XiDUXGIAiWHrLs3hKuDNc5CaqiU8/HSPRu0=";
            finalImageTag = "v1.17.1";
          };
          cert-manager-controller = pullImage {
            imageName = "quay.io/jetstack/cert-manager-controller";
            imageDigest = "sha256:9339837eaaa7852509fa4c89c12543721d79d7facf57f29adec7c96fffe408d6";
            hash = "sha256-Ct7IYjFEzHAMxLTZ1Hso2qaaRlkrOWgxRIbyHZHNimo=";
            finalImageTag = "v1.17.1";
          };
          cert-manager-startupapicheck = pullImage {
            imageName = "quay.io/jetstack/cert-manager-startupapicheck";
            imageDigest = "sha256:ac8ef0a934ae456d10d2ff5ee492b0a816bf55752f61354bde1739054c2c2c68";
            hash = "sha256-lsEJK5uuTQadqqoEAMoDxDWMI4K9340XHxdIiUtWKPk=";
            finalImageTag = "v1.17.1";
          };
          cert-manager-webhook = pullImage {
            imageName = "quay.io/jetstack/cert-manager-webhook";
            imageDigest = "sha256:2933ec670a99524a6860f641ef3720289d784b0bef35bd0b74fc3eb093e71596";
            hash = "sha256-AmgOyAVwxmeODed5w1xlB8PMqpl2A3i1rL6H1fITZkE=";
            finalImageTag = "v1.17.1";
          };
        };
      };
      nixidy = {
        charts,
        pkgs,
        ...
      }: {
        dotfiles.crds.cert-manager = {
          src = pkgs.fetchFromGitHub {
            owner = "cert-manager";
            repo = "cert-manager";
            rev = "v1.18.1";
            hash = "sha256-X2FWGW3085KKzXOce8j46xiPBjfH+K4clqrpQFpfWPA=";
          };
          prefix = "deploy/crds/crd-";
          crds = [
            "certificaterequests"
            "certificates"
            "challenges"
            "clusterissuers"
            "issuers"
            "orders"
          ];
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
            };
          };
          resources = let
            domainName = replaceStrings ["."] ["-"] domain;
            mkClusterIssuer = name: server: {
              metadata.annotations."chart.canivete.app/cert-manager" = "";
              spec.acme = {
                inherit server email;
                privateKeySecretRef = {inherit name;};
                solvers = toList (mkMerge [
                  {selector.dnsZones = [domain];}
                  (mkIf (provider ? google) {
                    dns01.cloudDNS = {
                      project = "";
                      serviceAccountSecretRef = {
                        name = "cert-manager";
                        key = "credentials.json";
                      };
                    };
                  })
                  (mkIf (provider ? cloudflare) {
                    dns01.cloudflare.apiTokenSecretRef = {
                      name = "cert-manager";
                      key = "cloudflare_api_token";
                    };
                  })
                ]);
              };
            };
          in {
            secrets.cert-manager.data = mkMerge [
              (mkIf (provider ? google) {"credentials.json" = toBase64 provider.google.credentials;})
              (mkIf (provider ? cloudflare) {cloudflare_api_token = toBase64 provider.cloudflare.token;})
            ];
            "cert-manager.io".v1 = {
              ClusterIssuer.letsencrypt-production = mkClusterIssuer "letsencrypt-production" "https://acme-v02.api.letsencrypt.org/directory";
              ClusterIssuer.letsencrypt-staging = mkClusterIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
              Certificate.${domainName}.spec = {
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
      kubenix = {helm, ...}: {
        canivete.ifd.crds = {
          certificates = "cert-manager.io/v1/Certificate";
          clusterissuers = "cert-manager.io/v1/ClusterIssuer";
        };
        kubernetes.helm.releases.cert-manager = {
          namespace = "security";
          chart = helm.fetch {
            repo = "https://charts.jetstack.io";
            chart = "cert-manager";
            version = "v1.17.1";
            sha256 = "sha256-CUKd2R911uTfr461MrVcefnfOgzOr96wk+guoIBHH0c=";
          };
          values = {
            crds.enabled = true;
            dns01RecursiveNameservers = concatStringsSep "," ["https://1.1.1.1:443/dns-query" "https://1.0.0.1:443/dns-query"];
            dns01RecursiveNameserversOnly = true;
            prometheus.enabled = true;
            prometheus.servicemonitor.enabled = services.prometheus.enable;
          };
          extraResources = let
            domainName = replaceStrings ["."] ["-"] domain;
            mkClusterIssuer = name: server: {
              metadata.annotations."chart.canivete.app/cert-manager" = "";
              spec.acme = {
                inherit server email;
                privateKeySecretRef = {inherit name;};
                solvers = toList (mkMerge [
                  {selector.dnsZones = [domain];}
                  (mkIf (provider ? google) {
                    dns01.cloudDNS = {
                      project = "";
                      serviceAccountSecretRef = {
                        name = "cert-manager";
                        key = "credentials.json";
                      };
                    };
                  })
                  (mkIf (provider ? cloudflare) {
                    dns01.cloudflare.apiTokenSecretRef = {
                      name = "cert-manager";
                      key = "cloudflare_api_token";
                    };
                  })
                ]);
              };
            };
          in {
            secrets.cert-manager.data = mkMerge [
              (mkIf (provider ? google) {"credentials.json" = toBase64 provider.google.credentials;})
              (mkIf (provider ? cloudflare) {cloudflare_api_token = toBase64 provider.cloudflare.token;})
            ];
            clusterissuers.letsencrypt-production = mkClusterIssuer "letsencrypt-production" "https://acme-v02.api.letsencrypt.org/directory";
            clusterissuers.letsencrypt-staging = mkClusterIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
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
