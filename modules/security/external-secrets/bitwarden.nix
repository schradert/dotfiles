{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://api.bitwarden.com" "https://identity.bitwarden.com"];
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    inherit (config.services.external-secrets) enable bitwarden;
    inherit (lib) flip mapAttrs mkIf mkOption recursiveUpdate toList types;
    mkStrOption = canivete.mkNullableOption types.str;
    image = {
      imageName = "ghcr.io/external-secrets/bitwarden-sdk-server";
      imageDigest = "sha256:5671059a04526644a79a1121504673260b9de2e329437ffd5118b827fe148cf1";
      hash = "sha256-jgkQuOp8KoxP6GzzEoudrF/KXdZoDtr7YTo/zXXs/PE=";
      finalImageTag = "v0.5.0";
    };
    certificate = recursiveUpdate {
      secretName = "bitwarden-tls-certs";
      dnsNames = [
        "external-secrets-bitwarden-sdk-server.security.svc.cluster.local"
        "bitwarden-sdk-server.security.svc.cluster.local"
        "localhost"
      ];
      ipAddresses = ["127.0.0.1" "::1"];
      privateKey.algorithm = "RSA";
      privateKey.encoding = "PKCS8";
      privateKey.size = 2048;
      issuerRef.kind = "ClusterIssuer";
      issuerRef.group = "cert-manager.io";
    };
  in {
    options.services.external-secrets.bitwarden = {
      organization_id = mkStrOption {};
      project_id = mkStrOption {};
    };
    config = mkIf enable {
      opentofu = {config, ...}: {
        options.dotfiles.secrets = mkOption {
          default = {};
          description = "Secrets to propagate from OpenTofu workspace to Bitwarden Secrets Manager";
          type = types.attrsOf (types.submodule ({name, ...}: {
            options.key = mkStrOption {default = name;};
            options.value = mkStrOption {};
            options.note = mkStrOption {default = "";};
          }));
        };
        config.plugins = ["maxlaverse/bitwarden/0.14.0"];
        config.modules.resource.bitwarden_secret = flip mapAttrs config.dotfiles.secrets (_: secret: {
          inherit (secret) key value note;
          inherit (bitwarden) project_id;
        });
      };
      nixos = {pkgs, ...}: {
        assertions = toList {
          assertion = config.services.cert-manager.enable;
          message = "External Secrets Bitwarden Secrets Manager needs Cert Manager";
        };
        canivete.kubernetes.images.bitwarden-sdk-server = pkgs.dockerTools.pullImage image;
      };
      kubenix.kubernetes.resources.secrets.external-secrets-bitwarden.data.token = canivete.toBase64 (canivete.vals.sops.default "bitwarden");
      nixidy.applications.external-secrets = {
        helm.releases.external-secrets.values.bitwarden-sdk-server = {
          enabled = true;
          image.repository = image.imageName;
          image.tag = image.finalImageTag;
          image.pullPolicy = "Never";
        };
        resources = {
          clusterIssuers.bitwarden-bootstrap-issuer.spec.selfSigned = {};
          certificates.bitwarden-bootstrap-certificate.spec = certificate {
            commonName = "cert-manager-bitwarden-tls";
            isCA = true;
            subject.organizations = ["external-secrets.io"];
            issuerRef.name = "bitwarden-bootstrap-issuer";
          };
          clusterIssuers.bitwarden-certificate-issuer.spec.ca.secretName = "bitwarden-tls-certs";
          certificates.bitwarden-tls-certs.spec = certificate {issuerRef.name = "bitwarden-certificate-issuer";};
          clusterSecretStores.bitwarden.spec.provider.bitwardensecretsmanager = {
            apiURL = "https://api.bitwarden.com";
            identityURL = "https://identity.bitwarden.com";
            auth.secretRef.credentials = {
              key = "token";
              name = "external-secrets-bitwarden";
            };
            bitwardenServerSDKURL = "https://bitwarden-sdk-server.security.svc.cluster.local:9998";
            caProvider.type = "Secret";
            caProvider.name = "bitwarden-tls-certs-tls";
            caProvider.key = "tls.crt";
            organizationID = bitwarden.organization_id;
            projectID = bitwarden.project_id;
          };
        };
      };
    };
  };
}
