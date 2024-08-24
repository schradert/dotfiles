{
  # [ ] [k8tz](https://github.com/k8tz/k8tz)
  perSystem.dotfiles.helm.k8tz = {
    namespace = "kube-system";
    chart = {
      repo = "https://k8tz.github.io/k8tz";
      chart = "k8tz";
      version = "0.16.2";
      sha256 = "sVdg7TG+6WB9+z+r2POJP9GrjIgTVgdj0omGAbqzMRU=";
    };
    values = {
      namespace = "kube-system";
      replicaCount = 2;
      timezone = "America/Los_Angeles";
      cronJobTimeZone = true;
    };
  };
}
