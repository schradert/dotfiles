{
  dotfiles = {
    config,
    lib,
    ...
  }: let
    inherit (lib) generators mkEnableOption mkIf;
    operatorVersion = "0.25.0";
    server.image = {
      name = "dotfiles/clickhouse-server-odbc";
      tag = "0.0.1";
    };
  in {
    options.services.clickhouse.enable = mkEnableOption "Clickhouse";
    config = mkIf config.services.clickhouse.enable {
      opentofu.passwords.clickhouse.length = 21;
      nixos = {pkgs, ...}: let
        inherit (pkgs) buildEnv dockerTools writeTextDir writeTextFile;
        inherit (dockerTools) buildImage pullImage;
      in {
        canivete.kubernetes.images = {
          clickhouse-operator = pullImage {
            imageName = "altinity/clickhouse-operator";
            imageDigest = "sha256:7a6ee16b4406a0891d9b14879f1222d7182d69176ff77fcd94ec8a90fb56b9f1";
            hash = "sha256-3zpDtmHsmpJU7PYcVeN/1uOZbQzrE6/GGobwfEAzLrE=";
            finalImageTag = operatorVersion;
          };
          metrics-exporter = pullImage {
            imageName = "docker.io/altinity/metrics-exporter";
            imageDigest = "sha256:5cc9291f4f7e16b36a5b26e69b8ca7d88c14b094d71b61fa429119dfd8e3a1a3";
            hash = "sha256-1L2/9P2LzW5KxVrPficb6PuYlV9Ji3z5VPRwcMLRelY=";
            finalImageTag = "0.24.3";
          };
          clickhouse-server = buildImage {
            inherit (server.image) name tag;
            fromImage = pullImage {
              imageName = "altinity/clickhouse-server";
              imageDigest = "sha256:63e9c94013a15cc63cc1ba3aac821cde33ed1a3ca2c081a8d651bb0694b742f6";
              hash = "sha256-Z0MQAY0sxPKhEoqWheWSOkci0tM3+xUGZU1Y58GNv38=";
              finalImageTag = "24.3.12.76.altinitystable";
            };
            # ODBC support
            copyToRoot = buildEnv {
              name = "image-root";
              # Upstream Debian image symlinks /bin and /lib to /usr/<dir>
              extraPrefix = "/usr";
              # ODBC config must live in root /etc
              postBuild = "mv $out/usr/etc $out/etc";
              paths = [
                # TODO why do I get "can't open lib '/lib/libtdsodbc.so': file not found" when pkgs.freetds is copied in
                # I install ODBC dependencies in a wrapper entrypoint with apt-get for now
                # freetds
                (writeTextFile {
                  name = "entrypoint.sh";
                  destination = "/bin/dotfiles-entrypoint.sh";
                  executable = true;
                  text = ''
                    #!/usr/bin/env bash
                    apt-get update
                    apt-get install -y --no-install-recommends \
                      unixodbc \
                      freetds-bin \
                      freetds-common \
                      freetds-dev \
                      libct4 \
                      libsybdb5 \
                      tdsodbc
                    /entrypoint.sh "$@"
                  '';
                })
                (writeTextDir "etc/odbcinst.ini" (generators.toINI {} {FreeTDS.Driver = "/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so";}))
                # TODO how to pass this file in through a volume?
                (writeTextDir "etc/odbc.ini" (generators.toINI {} {
                  # FIXME only add actual databases here
                  test = {
                    Driver = "FreeTDS";
                    Server = "100.64.0.3";
                    Port = 1433;
                  };
                }))
              ];
            };
            # Must copy upstream runtime config
            config = {
              Entrypoint = ["/bin/dotfiles-entrypoint.sh"];
              Env = [
                "TZ=UTC"
                "LANG=en_US.UTF-8"
                "LANGUAGE=en_US:en"
                "LC_ALL=en_US.UTF-8"
                "CLICKHOUSE_CONFIG=/etc/clickhouse-server/config.xml"
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
              ];
              ExposedPorts = {
                "8123/tcp" = {};
                "9000/tcp" = {};
                "9009/tcp" = {};
              };
              Labels = {
                "org.opencontainers.image.ref.name" = "ubuntu";
                "org.opencontainers.image.version" = "22.04";
              };
              Volumes."/var/lib/clickhouse" = {};
            };
          };
        };
      };
      nixidy = {
        lib,
        pkgs,
        ...
      }: {
        dotfiles.crds.clickhouse = {
          install = true;
          prefix = "deploy/helm/clickhouse-operator/crds";
          src = pkgs.fetchFromGitHub {
            owner = "Altinity";
            repo = "clickhouse-operator";
            rev = "release-0.24.3";
            hash = "sha256-8y5YVfrhtmP8Nti2HGPVG8t3RPgsUEyGEfTfbex84bI=";
          };
        };
        applications.clickhouse = {
          namespace = "storage";
          dotfiles.volsync.pvcs.clickhouse.title = "clickhouse-data-chi-clickhouse-clickhouse-0-0-0";
          helm.releases.clickhouse = {
            chart = lib.helm.downloadHelmChart {
              chart = "clickhouse";
              version = "0.2.2";
              repo = "https://helm.altinity.com";
              chartHash = "sha256-ooNxXM6axFT8tVVtekHs83vQFl2i6FUe9cc0KeCxQTo=";
            };
            values = {
              clickhouse.defaultUser = {
                # TODO default user secret password
                # password = canivete.vals.sops.default "passwords/clickhouse";
                hostIP = "10.0.0.0/24";
              };
              clickhouse.image = {
                repository = server.image.name;
                inherit (server.image) tag;
              };
              operator.operator.image.tag = operatorVersion;
            };
          };
        };
      };
    };
  };
}
