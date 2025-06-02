{
  # TODO user accounts?
  # TODO what about collaboration with excalidraw-room? https://github.com/excalidraw/excalidraw-room
  # TODO mermaid-to-excalidraw?
  # TODO find a wrapper application!
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: {
    options.services.excalidraw = {
      enable = lib.mkEnableOption "";
      release = canivete.mkModuleOption {};
    };
    config = lib.mkIf config.services.excalidraw.enable {
      nixos = {pkgs, ...}: {
        canivete.kubernetes.images.excalidraw = pkgs.dockerTools.pullImage {
          imageName = "excalidraw/excalidraw";
          imageDigest = "";
          hash = "";
        };
      };
      kubenix.kubernetes.helm.releases.excalidraw = {...}: {
        imports = [config.services.excalidraw.release];
        values = {
          controllers.excalidraw.containers.excalidraw = {
            image.repository = "excalidraw/excalidraw";
            probes.liveness.enabled = true;
            probes.readiness.enabled = true;
            probes.startup.enabled = true;
          };
          service.excalidraw.controller = "excalidraw";
          service.excalidraw.ports.http.port = 80;
          serviceAccount.create = true;
          ingress.excalidraw.hosts = lib.toList {
            host = "excalidraw.${config.domain}";
            paths = lib.toList {
              path = "/";
              service.identifier = "excalidraw";
              service.port = "http";
            };
          };
        };
      };
    };
  };
}
