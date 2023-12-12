{
  config,
  lib,
  pkgs,
  ...
}: {
  options.namespaces.existing = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    example = ["another-existing-namespace"];
    description = lib.mdDoc "Namespaces that are not managed by FluxCD";
  };
  options.namespaces.new = lib.mkOption {
    type = lib.types.addCheck (lib.types.listOf lib.types.str) (lib.lists.mutuallyExclusive config.namespaces.existing);
    default = [];
    example = ["traefik" "prometheus"];
    description = lib.mdDoc "Namespaces to create on the cluster";
  };
  options.namespaces.all = lib.mkOption rec {
    type = lib.types.addCheck (lib.types.listOf lib.types.str) (all: all == default);
    default = config.namespaces.existing ++ config.namespaces.new;
    description = lib.mdDoc "Don't override!";
  };
  config.resources = pkgs.map' config.namespaces.new (namespace: {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = namespace;
  });
  config.namespaces.existing = ["default" "flux-system"];
}
