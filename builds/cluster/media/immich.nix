{nix, ...}: {
  # TODO look into immich-go vs immich-cli for photo upload
  # TODO build immich with nix
  # NOTE https://github.com/immich-app/immich
  perSystem.canivete.dream2nix.packages = {
    # NOTE currently failing with @msgpackr-extract/msgpackr-extract-darwin-x64 not found in package-lock.json""
    immich.module = {
      config,
      dream2nix,
      ...
    }: let
      inherit (config) version deps mkDerivation;
      inherit (deps) fetchFromGitHub;
      inherit (mkDerivation) src;
    in {
      imports = with dream2nix.modules.dream2nix; [nodejs-package-lock-v3 nodejs-granular-v3];
      deps = {nixpkgs, ...}: {inherit (nixpkgs) fetchFromGitHub;};
      name = "immich";
      version = "1.112.1";
      mkDerivation.src = fetchFromGitHub {
        owner = "immich-app";
        repo = "immich";
        rev = "v${version}";
        hash = "sha256-O014Y2HwhfPqKKFFGtNDJBzCaR6ugI4azw6/kfzKET0=";
      };
      mkDerivation.sourceRoot = "${src.name}/server";
      nodejs-package-lock-v3.packageLockFile = "${src}/server/package-lock.json";
    };
    # NOTE currently failing with "
    # ERROR: Could not find a version that satisfies the requirement python (from versions: none)
    # ERROR: No matching distribution found for python"
    # while running "bash -c $(nix-build ...refresh.drv --no-link)/bin/refresh"
    # TODO pass poetry.lock to pin dependencies
    immich-machine-learning.module = {
      config,
      dream2nix,
      ...
    }: let
      inherit (config) deps mkDerivation version;
      inherit (mkDerivation) src;
      inherit (deps) fetchFromGitHub python;
      pyproject = nix.fromTOML (nix.readFile "${src}/machine-learning/pyproject.toml");
    in {
      imports = [dream2nix.modules.dream2nix.pip];
      paths.package = src;
      deps = {nixpkgs, ...}: {
        inherit (nixpkgs) fetchFromGitHub;
        python = nixpkgs.python312;
      };
      inherit (pyproject.tool.poetry) name version;
      mkDerivation = {
        src = fetchFromGitHub {
          owner = "immich-app";
          repo = "immich";
          rev = "v1.112.1";
          hash = "sha256-O014Y2HwhfPqKKFFGtNDJBzCaR6ugI4azw6/kfzKET0=";
        };
        sourceRoot = "${src.name}/machine-learning";
        buildInputs = pyproject.build-system.requires;
      };
      buildPythonPackage.pyproject = true;
      pip.requirementsList = nix.attrNames pyproject.tool.poetry.dependencies;
      pip.flattenDependencies = true;
    };
  };
  perSystem.dotfiles.helm.immich = {
    namespace = "media";
    resources.persistentVolumeClaims.immich = {
      metadata.namespace = "immich";
      spec.accessModes = ["ReadWriteOnce"];
      spec.resources.requests.storage = "10Gi";
    };
    chart = {
      repo = "https://immich-app.github.io/immich-charts";
      chart = "immich";
      version = "0.7.1";
      sha256 = "85dZNeRKUR3b6QB/iHZQLtp4cwEirixZ6E2rpLD68EE=";
    };
    values = {
      immich.persistence.library.existingClaim = "immich";
      postgresql.enabled = true;
      redis.enabled = true;
    };
  };
}
