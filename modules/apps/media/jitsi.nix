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
    forceImage = image: mkForce "${image.imageName}:${image.finalImageTag}";
    images = {
      jigasi = {
        imageName = "jitsi/jigasi";
        imageDigest = "sha256:09cc2db72c7cbb42bbf83971557bbd2a05795786279e61f33846b5a122defe4b";
        hash = "sha256-FnuhKLqmGAcJ7xtWA/BxNHF8WdI6F3dg1c4pHbeBoaY=";
        finalImageTag = "jigasi-1.1-392-g03d83b3-1";
      };
      jibri = {
        imageName = "jitsi/jibri";
        imageDigest = "sha256:f88679156fed5b9d77fc3cfaf0e91da7e7924d58c778caa57762921b99751a4a";
        hash = "sha256-/T2fsjvXJQL2fnl6DkWxR5Eur7l97QjZCoJOTEg+0K8=";
        finalImageTag = "jibri-8.0-183-g7b406bf-1";
      };
      jicofo = {
        imageName = "jitsi/jicofo";
        imageDigest = "sha256:032f298a60cff6a9f5fb1b48e42f28e30d3d8622fc735c995c080a1d7393be22";
        hash = "sha256-zTXc3bbzZ/0GOvbNHUQROuQDTwpCYL4h3oLZYCfkC7c=";
        finalImageTag = "jicofo-1.0-1152-1";
      };
      jvb = {
        imageName = "jitsi/jvb";
        imageDigest = "sha256:364440dab80da7e2fbfe08b69fe4b9d822b9d331e1e91790242bbc014f3b980e";
        hash = "sha256-pQE0Kd2pPfoJSwvsO8Ob3k8fMK+soGdeLUTJHJAu84A=";
        finalImageTag = "jvb-2.3-247-g6fc76e46b-1";
      };
      jitsi-web = {
        imageName = "jitsi/web";
        imageDigest = "sha256:73c48b1f36358f21aeb900cf50231b1e860f45e7c32d7931b92723324bedab37";
        hash = "sha256-KjoK5UCORzIcyQuNH8KVNrFk5CRKW+cZihZ1W23wnLc=";
        finalImageTag = "web-1.0.8725-1";
      };
      prosody = {
        imageName = "jitsi/prosody";
        imageDigest = "sha256:f7a438d4a837e93c719411c5bb9f764895efa0f96354bb032a64f6b4a5669510";
        hash = "sha256-5C3PIT4+Sye2EB53DkZSNXaLhQl3rr//P2mRIz6ZMOM=";
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
                image.pullPolicy = "Never";
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
                web.image.repository = images.jitsi-web.imageName;
                jicofo.image.repository = images.jicofo.imageName;
                jicofo.metrics.image = with images.jicofo-prometheus-exporter; {
                  repository = imageName;
                  tag = finalImageTag;
                };
                jvb.image.repository = images.jvb.imageName;
                jvb.metrics.image = with images.jvb-prometheus-exporter; {
                  repository = imageName;
                  tag = finalImageTag;
                  pullPolicy = "Never";
                };
                jigasi.image.repository = images.jigasi.imageName;
                jibri.image.repository = images.jibri.imageName;
                prosody.image = with images.prosody; {
                  repository = imageName;
                  tag = finalImageTag;
                };
                prosody.metrics.image = with images.prosody-otel; {
                  repository = imageName;
                  tag = finalImageTag;
                  pullPolicy = "Never";
                };
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
              # Pin images
              deployments = {
                jitsi-jitsi-meet-jibri.spec.template.spec.containers = toList {
                  name = "jitsi-meet";
                  image = forceImage images.jibri;
                };
                jitsi-jitsi-meet-jicofo.spec.template.spec.containers = toList {
                  name = "jitsi-meet";
                  image = forceImage images.jicofo;
                };
                jitsi-jitsi-meet-jigasi.spec.template.spec.containers = toList {
                  name = "jitsi-meet";
                  image = forceImage images.jigasi;
                };
                jitsi-jitsi-meet-jvb.spec.template.spec.containers = toList {
                  name = "jitsi-meet";
                  image = forceImage images.jvb;
                };
                jitsi-jitsi-meet-web.spec.template.spec.containers = toList {
                  name = "jitsi-meet";
                  image = forceImage images.jitsi-web;
                };
              };
              pods.jitsi-jitsi-meet-web-test-connection.spec.containers = toList {
                name = "wget";
                image = forceImage images.jitsi-busybox;
              };
              pods.jitsi-prosody-test-connection.spec.containers = toList {
                name = "wget";
                image = forceImage images.jitsi-busybox;
              };
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
