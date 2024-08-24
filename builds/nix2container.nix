{config, nix, ...}: with nix; let
  subdomain = "harbor.${config.dotfiles.domain}";
in {
  perSystem = {config, inputs', pkgs, self', system, ...}: {
    options.dotfiles.nix2container = mkOption {
      default = {};
      type = attrsOf (submodule ({name, config, ...}: {
        options = {
          registry = mkOption {
            type = str;
            default = subdomain;
          };
          repository = mkOption {
            type = str;
            default = name;
          };
          package = mkOption {
            type = package;
            default = self'.packages.${name} or pkgs.${name};
          };
          args = mkOption {
            type = attrsOf anything;
            default = {};
          };
          image = mkOption {
            type = package;
            default = pipe config.args [
              (recursiveUpdate {
                name = "${config.registry}/${config.repository}";
                config.entrypoint = [(getExe config.package)];
              })
              inputs'.nix2container.packages.nix2container.buildImage
            ];
          };
        };
      }));
    };
    config.canivete.opentofu.workspaces.deploy.modules.nix2container = {
      config = mkMerge (flip mapAttrsToList config.dotfiles.nix2container (name: container: let
        path = "dotfiles.${replaceStrings ["darwin"] ["linux"] system}.nix2container.${name}.image";
      in {
        resource.null_resource.kubernetes = {
          depends_on = ["null_resource.${name}"];
          provisioner.local-exec.environment = pipe ["tag" "registry" "repository" "fullRepository"] [
            (flip genAttrs (attr: "\${ data.external.${name}.result.${attr} }"))
            (mapAttrNames (key: "${toUpper name}_IMAGE_${toUpper key}"))
          ];
        };
        data.external.${name}.program = pkgs.execBash ''
          export \
            drv=$(nix path-info --derivation .#${path}) \
            tag=$(nix eval --raw .#${path}.imageTag) \
            registry=${container.registry} \
            repository=${container.repository} \
            fullRepository=${container.registry}/${container.repository}
          ${getExe pkgs.jq} --null-input '$ARGS.positional | map({(.):env[.]}) | add' --args drv tag registry repository fullRespository
        '';
        resource.null_resource.${name} = {
          triggers.drv = "\${ data.external.${name}.result.drv }";
          provisioner.local-exec.command = "nix run .#${path}.copyToRegistry";
        };
      }));
    };
  };
}
