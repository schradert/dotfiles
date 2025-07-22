{
  # TODO integrate with excalidraw https://github.com/jitsi/excalidraw-backend
  # TODO look through useful plugins https://github.com/jitsi-contrib/prosody-plugins
  # TODO should I deploy a STUN server?
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://jitsi-contrib.github.io/jitsi-helm"];
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (config) services;
    inherit (lib) mkEnableOption mkForce mkIf mkMerge toList;
    hostname = "jitsi.${config.domain}";
    # Jitsi uses the same tag for updated digests...
    pinImage = image: {
      repository = image.imageName;
      tag = "${image.finalImageTag}@${image.imageDigest}";
    };
    busybox = with images.jitsi-busybox; "${imageName}:${finalImageTag}";
    images = {
      jigasi = {
        imageName = "jitsi/jigasi";
        imageDigest = "sha256:29623c814dcd4073d8920bd6f7248b2ac088bbab173799b096ad586eb245d2bc";
        hash = "sha256-f7WAjuR+oMGKLzE5PEl9O8G46sHGAJYLMY+LQ8ZFu8I=";
        finalImageTag = "jigasi-1.1-392-g03d83b3-1";
      };
      jibri = {
        imageName = "jitsi/jibri";
        imageDigest = "sha256:34c446ef243ec9aebd232471110d4b9b28ccceaeb9b78898362fe479e88863b8";
        hash = "sha256-QJBZLIsc3pH7g3CqS4Y+0eomy//yVNNhuPPNIjtW6xU=";
        finalImageTag = "jibri-8.0-183-g7b406bf-1";
      };
      jicofo = {
        imageName = "jitsi/jicofo";
        imageDigest = "sha256:3830c204714ecde016cb7beb96fb1297fd58d62d40738ba56b9458471241e805";
        hash = "sha256-UqCkCpFbDalYffcwbMh1NG95HgaBDEa4mspxdwwZRNU=";
        finalImageTag = "jicofo-1.0-1152-1";
      };
      jvb = {
        imageName = "jitsi/jvb";
        imageDigest = "sha256:595d7620a9be0067b286e07557b57b6ec2d127a69c3e9616ff3d6d5fd1e8e4d9";
        hash = "sha256-MVb+xhlt2r2ENNoDZxCu6hG793KoRwx+Dw1qapbQvmQ=";
        finalImageTag = "jvb-2.3-249-g9a2123ad4-1";
      };
      jitsi-web = {
        imageName = "jitsi/web";
        imageDigest = "sha256:8f9389696b1b1865bf460092da6fc6253618082f529d6357651f32d6119ddc0c";
        hash = "sha256-iF86zCqyPiDO4VI7errQqATGLGn9LBS6ndCDRaDutE8=";
        finalImageTag = "web-1.0.8730-1";
      };
      prosody = {
        imageName = "jitsi/prosody";
        imageDigest = "sha256:da3b66391e0475792ef409d81caf3e2f0d402cb6a537c5e5dca5de1f20903284";
        hash = "sha256-UhZ5SW5R0X6DiEFLob4DPjtAgnRVZaEnUri6RfyVKtE=";
        finalImageTag = "prosody-13.0.2";
      };
      jitsi-busybox = {
        imageName = "busybox";
        imageDigest = "sha256:18ac7a6883a86416ade8178063c26deff577cd831445f5c5ac5c7a931cb60983";
        hash = "sha256-7hNq1iGGAsJsTTzI/UrLm7S4MKBaNPcLh3rFp2xqkP4=";
        finalImageTag = "1.37.0-glibc";
      };
      # TODO make these dependent on prometheus
      jicofo-prometheus-exporter = {
        imageName = "prayagsingh/prometheus-jicofo-exporter";
        imageDigest = "sha256:50d4ac714856924faed7ad426be796cb00261b277fe4f723b72f9e6b18011469";
        hash = "sha256-MAIFLcMWkHYqELcJnn8TuPHiEJK4x7bieR+I3y/Af7g=";
        finalImageTag = "1.3.2";
      };
      jvb-prometheus-exporter = {
        imageName = "systemli/prometheus-jitsi-meet-exporter";
        imageDigest = "sha256:638f605bd1af27afb6a89eccff7d71faa2ea08ab27669f7a81eb51bc16fd04cf";
        hash = "sha256-ude+dzJMi+E7WXCSNij3G+9JMSYJ0RvNc7TObUVhr+s=";
        finalImageTag = "1.3";
      };
      prosody-otel = {
        imageName = "otel/opentelemetry-collector-contrib";
        imageDigest = "sha256:c0629f14f72cb36f03d77169011201e9050c78adec4b9167a2252b6ec3e7a586";
        hash = "sha256-V1Bxq30K5c/Km8KqVNyoVeVBBkQ+CUcnPHKoRxRrZs8=";
        finalImageTag = "0.130.0";
      };
    };
  in {
    options.services.jitsi.enable = mkEnableOption "Jitsi";
    config = mkIf config.services.jitsi.enable {
      nixos = {pkgs, ...}: {canivete.kubernetes.images = builtins.mapAttrs (_: pkgs.dockerTools.pullImage) images;};
      opentofu = {
        passwords = {
          jitsi-jigasi.length = 10;
          jitsi-jigasi.special = false;
          jitsi-jibri.length = 10;
          jitsi-jibri.special = false;
          jitsi-recorder.length = 10;
          jitsi-recorder.special = false;
          jitsi-jicofo.length = 10;
          jitsi-jicofo.special = false;
          jitsi-jicofo-component.length = 10;
          jitsi-jicofo-component.special = false;
          jitsi-jvb.length = 10;
          jitsi-jvb.special = false;
        };
        dotfiles.secrets = {
          "jitsi/jigasi".value = "\${ random_password.jitsi-jigasi.result }";
          "jitsi/jibri".value = "\${ random_password.jitsi-jibri.result }";
          "jitsi/recorder".value = "\${ random_password.jitsi-recorder.result }";
          "jitsi/jicofo".value = "\${ random_password.jitsi-jicofo.result }";
          "jitsi/component".value = "\${ random_password.jitsi-jicofo-component.result }";
          "jitsi/jvb".value = "\${ random_password.jitsi-jvb.result }";
        };
      };
      nixidy = {lib, ...}: {
        applications.jitsi = {
          namespace = "dotfiles";
          dotfiles.volsync.pvcs = {
            jibri.title = "jitsi-jitsi-meet-jibri";
            prosody.title = "prosody-data";
          };
          helm.releases.jitsi = {
            chart = lib.helm.downloadHelmChart {
              chart = "jitsi-meet";
              version = "1.5.1";
              repo = "https://jitsi-contrib.github.io/jitsi-helm";
              chartHash = "sha256-ohIP3j7w0H9pT8Lyi7329k1pgtPn5QWOAeJ8uyligC8=";
            };
            values = mkMerge [
              {
                enableAuth = true;
                enableGuests = false;
                publicURL = hostname;
                websockets.colibri.enablied = true;
                websockets.xmpp.enabled = true;
                jigasi.enabled = true;
                jibri = {
                  enabled = true;
                  singleUseMode = true;
                  livestreaming = true;
                  persistence.enabled = true;
                  shm.enabled = true;
                  shm.useHost = true;
                };
                # TODO why do I have to have a public IP?
                jvb.publicIPs = ["192.168.50.254"];
                # TODO should I manage an XMPP server independently of Jitsi?
                prosody.enabled = true;
                prosody.persistence.enabled = true;
              }
              {
                # Pin images
                image.pullPolicy = "Never";
                jibri.image = pinImage images.jibri;
                jicofo.image = pinImage images.jicofo;
                jigasi.image = pinImage images.jigasi;
                jvb.image = pinImage images.jvb;
                web.image = pinImage images.jitsi-web;
                prosody.image = pinImage images.prosody;

                jicofo.metrics.image = pinImage images.jicofo-prometheus-exporter;
                jvb.metrics.image = pinImage images.jvb-prometheus-exporter;
                prosody.metrics.image = pinImage images.prosody-otel;
              }
              (mkIf services.prometheus.enable {
                jicofo.metrics.enabled = true;
                jibri.metrics.enabled = true;
                jvb.metrics.enable = true;
                jvb.metrics.grafanaDashboards.enabled = services.grafana.enable;
                prosody.metrics.enable = true;
              })
            ];
          };
          resources = mkMerge [
            {
              pods.jitsi-jitsi-meet-web-test-connection.spec.containers.wget.image = mkForce busybox;
              pods.jitsi-prosody-test-connection.spec.containers.wget.image = mkForce busybox;
            }
            (mkIf services.cilium.enable {
              # TODO HTTPRoute for JVB
              httpRoutes.jitsi-web.spec = {
                hostnames = [hostname];
                parentRefs = toList {
                  name = "internal";
                  namespace = "kube-system";
                  sectionName = "https";
                };
                rules = toList {
                  backendRefs = toList {
                    name = "jitsi-jitsi-meet-web";
                    port = 80;
                  };
                };
              };
            })
            (mkIf services.external-secrets.enable {
              secrets = {
                # TODO how can I actually remove these from the generated output?
                jitsi-prosody-jibri.data = mkForce {};
                jitsi-prosody-jicofo.data = mkForce {};
                jitsi-prosody-jigasi.data = mkForce {};
                jitsi-prosody-jvb.data = mkForce {};
                jitsi-prosody.data = mkForce {};
              };
              externalSecrets = {
                jitsi-prosody-jibri.spec = {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  data = [
                    {
                      secretKey = "recorder";
                      remoteRef.key = "jitsi/recorder";
                    }
                    {
                      secretKey = "jibri";
                      remoteRef.key = "jitsi/jibri";
                    }
                  ];
                  target.template.data = {
                    JIBRI_RECORDER_PASSWORD = "{{ .recorder }}";
                    JIBRI_RECORDER_USER = "recorder";
                    JIBRI_XMPP_PASSWORD = "{{ .jibri }}";
                    JIBRI_XMPP_USER = "jibri";
                  };
                };
                jitsi-prosody-jicofo.spec = {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  data = [
                    {
                      secretKey = "jicofo";
                      remoteRef.key = "jitsi/jicofo";
                    }
                    {
                      secretKey = "component";
                      remoteRef.key = "jitsi/component";
                    }
                  ];
                  target.template.data = {
                    JICOFO_AUTH_PASSWORD = "{{ .jicofo }}";
                    JICOFO_AUTH_USER = "focus";
                    JICOFO_COMPONENT_SECRET = "{{ .component }}";
                  };
                };
                jitsi-prosody-jigasi.spec = {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  data = toList {
                    secretKey = "jigasi";
                    remoteRef.key = "jitsi/jigasi";
                  };
                  target.template.data = {
                    JIGASI_XMPP_PASSWORD = "{{ .jigasi }}";
                    JIGASI_XMPP_USER = "jigasi";
                  };
                };
                jitsi-prosody-jvb.spec = {
                  secretStoreRef.name = "bitwarden";
                  secretStoreRef.kind = "ClusterSecretStore";
                  data = toList {
                    secretKey = "jvb";
                    remoteRef.key = "jitsi/jvb";
                  };
                  target.template.data = {
                    JVB_AUTH_PASSWORD = "{{ .jvb }}";
                    JVB_AUTH_USER = "jvb";
                  };
                };
              };
            })
          ];
        };
      };
    };
  };
}
