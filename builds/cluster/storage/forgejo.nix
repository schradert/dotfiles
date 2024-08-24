{config, ...}: {
  perSystem.dotfiles.helm.forgejo = {
    namespace = "storage";
    chart = {
      chartUrl = "oci://code.forgejo.org/forgejo-helm/forgejo";
      chart = "forgejo";
      version = "8.1.2";
      sha256 = "gpkBBdHtC5uaynOPRjgai5CTfZhOCeCCtsal9tJXgPY=";
    };
    values.gitea.config.server.DOMAIN = "forgejo.${config.dotfiles.domain}";
  };
}
