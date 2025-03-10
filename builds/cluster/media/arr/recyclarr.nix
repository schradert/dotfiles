{
  perSystem.canivete.nix2container.recyclarr = {};
  perSystem.canivete.kubenix.helm.recyclarr.namespace = "media";
  perSystem.canivete.kubenix.helm.recyclarr.values = {
    secrets.recyclarr.enabled = true;
    secrets.recyclarr.stringData = {
      RADARR_API_KEY = "ref+envsubst://RADARR__AUTH__APIKEY";
      SONARR_API_KEY = "ref+envsubst://SONARR__AUTH__APIKEY";
    };
    configMaps.recyclarr.enabled = true;
    configMaps.recyclarr.data = {
      # TODO Figure out what all the settings I need are
    };
    controllers.recyclarr = {
      type = "cronjob";
      cronjob.schedule = "@daily";
      containers.recyclarr = {
        image.repository = "ref+envsubst://RECYCLARR_IMAGE_FULLREPOSITORY+";
        image.tag = "ref+envsubst://RECYCLARR_IMAGE_TAG";
        args = ["sync"];
        envFrom = [
          {secret = "recyclarr";}
          {configMapRef.name = "recyclarr";}
        ];
      };
    };
    # TODO figure out persistence needs
  };
}
