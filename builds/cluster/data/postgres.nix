{
  config,
  nix,
  ...
}:
with nix; let
  subdomain = "data.${config.dotfiles.domain}";
in {
  # OperatorConfiguration has a configuration field, not spec, so we need this to pass validation
  # NOTE https://github.com/hall/kubenix/issues/34
  perSystem.canivete.kubenix.clusters.prod.modules.postgres-patch.options.kubernetes.api.resources."acid.zalan.do".v1.OperatorConfiguration = mkOption {
    type = attrsOf (submodule {options.configuration = mkOption {type = attrsOf anything;};});
  };
  perSystem.dotfiles.helm = {
    postgres = {
      namespace = "data";
      chart = {
        repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
        chart = "postgres-operator";
        version = "1.12.2";
        sha256 = "3LJs4TYJob9lwB5lmSdNYRq8r7kB8EMxG0WqkQX93aU=";
      };
      values.configGeneral.enable_crd_registration = true;
      values.controllerID.create = true;
      resources.postgresqls.main.spec = {
        teamId = "acid";
        volume.size = "1Gi";
        numberOfInstances = 1;
        users.zalando = ["superuser" "createdb"];
        users.foo_user = [];
        databases.foo = "zalando";
        preparedDatabases.bar = {};
        postgresql.version = "16";
      };
    };
    postgres-ui = {
      namespace = "data";
      chart = {
        repo = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui";
        chart = "postgres-operator-ui";
        version = "1.12.2";
        sha256 = "SkuTSWzFhQV4lYgTnSWCuwAHloOz4dz7K8YreNEltes=";
      };
      values.envs.resourcesVisible = "True";
      values.envs.targetNamespace = "*";
      values.ingress = {
        enabled = true;
        ingressClassName = "external";
        hosts = nix.toList {
          host = subdomain;
          paths = ["/"];
        };
      };
    };
  };
}
