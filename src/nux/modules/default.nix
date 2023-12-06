{lib, ...}: {
  imports = [
    ./namespaces.nix
    ./helmrepositories.nix
    ./gitrepositories.nix
    ./helmreleases.nix
    ./kustomizations.nix
  ];
  options.resources = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [];
    description = lib.mdDoc "All of the resources to create in the cluster";
  };
  options.assertions = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        assertion = lib.mkOption {
          type = lib.types.bool;
          description = "Boolean expression of the assertion";
        };
        message = lib.mkOption {
          type = lib.types.str;
          description = "Message to display if the assertion is false";
        };
      };
    });
    default = [];
    internal = true;
    description = lib.mdDoc "Checks of valid configuration";
  };
}
