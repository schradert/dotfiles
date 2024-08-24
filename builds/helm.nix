{nix, ...}:
with nix; {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    options.dotfiles.helm = mkOption {
      default = {};
      type = attrsOf (submodule {
        freeformType = anything;
        options = {
          chart = mkOption {
            type = attrsOf anything;
            default = {};
          };
          values = mkOption {
            inherit (pkgs.formats.yaml {}) type;
            default = {};
          };
          resources = mkOption {
            inherit (pkgs.formats.yaml {}) type;
            default = {};
          };
        };
      });
    };
    config.canivete.kubenix.clusters.prod.modules.helm = {helm, ...}: {
      config = mkMerge (flip mapAttrsToList config.dotfiles.helm (name: cfg: {
        kubernetes = {
          resources = mkMerge [
            cfg.resources
            # TODO fix this with resources.imports
            (flip mapAttrs cfg.resources (_: type: flip mapAttrs type (_: _: {metadata.namespace = mkDefault cfg.namespace;})))
          ];
          helm.releases.${name} = mkMerge [
            (removeAttrs cfg ["chart" "resources"])
            {
              chart = pipe cfg.chart [
                # Good template chart to make deployment easier and more powerful
                (mergeAttrs {
                  repo = "https://bjw-s.github.io/helm-charts";
                  chart = "app-template";
                  version = "3.3.2";
                  sha256 = "9Lx3jPGiLaE+joGy2GWxLzjWDu8wCa+4DrS9atf2zug=";
                })
                helm.fetch
              ];
            }
          ];
        };
      }));
    };
  };
}
