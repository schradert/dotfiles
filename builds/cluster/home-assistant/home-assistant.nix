{
  # TODO kubernetes deployment
  # NOTE https://github.com/bjw-s/helm-charts/blob/main/examples/helm/home-assistant/values.yaml
  perSystem.canivete.arion.modules.home-assistant.services.home-assistant = {
    nixos.configuration.services.home-assistant = {
      # NOTE https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/home-automation/home-assistant.nix
      enable = true;
      openFirewall = true;
      # TODO COMPONENTS
      # NOTE https://www.home-assistant.io/integrations/
      # extraComponents = [];
      # customComponents = haPkgsComps: [];
      # TODO what python packages do I need? postgres?
      # extraPackages = pypkgs: [];
      # TODO configure UI
      # NOTE https://www.home-assistant.io/lovelace/dashboards/
      # lovelaceConfig = {};
      # lovelaceConfigWritable = true; (temporarily?)
      # customLovelaceModules = haPkgsLovelace: [];
      # config.lovelace.mode = "yaml";
      # TODO all that good config
      # TODO do I need a separate deployment for each house?
      # NOTE https://www.home-assistant.io/docs/configuration/secrets/
      # NOTE https://www.home-assistant.io/docs/configuration/basic/
      # NOTE https://www.home-assistant.io/integrations/
      # config = {};
      # NOTE https://github.com/home-assistant/core/blob/dev/homeassistant/bootstrap.py#L109
      # defaultIntegrations = [];
    };
    nixos.useSystemd = true;
  };
}
