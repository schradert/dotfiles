{config, ...}: {
  perSystem.canivete.kubenix.clusters.prod.deploy.fetchKubeconfig = "ssh sirver sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${config.dotfiles.domain}/'";
}
