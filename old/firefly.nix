{
  config,
  lib,
  pkgs,
  ...
}: {
  config.resource.random_password.firefly-app-key = {length = 32;};
  config.resource.kubernetes_namespace.firefly = {metadata.name = "firefly";};
  config.resource.kubernetes_secret.firefly-app-key = {
    depends_on = ["kubernetes_namespace.firefly"];
    metadata.name = "firefly-app-key";
    metadata.namespace = "firefly";
    data.APP_KEY = "\${ random_password.firefly-app-key.result }";
  };
  config.resource.helm_release.firefly = {
    depends_on = ["kubernetes_secret.firefly-app-key"];
    name = "firefly";
    repository = "https://firefly-iii.github.io/kubernetes";
    version = "0.7.2";
    chart = "firefly-iii-stack";
    namespace = "firefly";
    values = pkgs.toYAML {
      firefly-db.storage.class = "local-path";
      firefly-iii.config.existingSecret = "firefly-app-key";
    };
  };
}
