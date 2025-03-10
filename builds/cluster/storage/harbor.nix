{
  # https://github.com/goharbor/harbor
  # https://goharbor.io/docs/2.11.0/install-config/harbor-ha-helm/
  # TODO package harbor from source
  perSystem.canivete.kubenix.helm.harbor = {
    namespace = "storage";
    chart = {
      repo = "https://helm.goharbor.io";
      chart = "harbor";
      version = "1.15.0";
      sha256 = "gj3Z00+ZwznFZP84ezl6lgEeAfBso/2+M/OfCYWlC0Y=";
    };
    # Has to be a string!
    # TODO https://github.com/aquasecurity/trivy
    values.trivy.resources.limits.cpu = "1";
  };
}
