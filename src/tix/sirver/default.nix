{config, ...}: {
  provider.helm = {inherit (config.provider) kubernetes;};
  terraform.required_providers = {
    github.source = "integrations/github";
    github.version = "5.42.0";
    flux.source = "fluxcd/flux";
    flux.version = "1.1.2";
  };
  resource.tls_private_key.flux = {
    algorithm = "ECDSA";
    ecdsa_curve = "P256";
  };
  resource.github_repository_deploy_key.flux = {
    key = "\${ tls_private_key.flux.public_key_openssh }";
    read_only = false;
    repository = "dotfiles";
    title = "Flux (${config.locals.cluster.name})";
  };
  provider.flux = {
    kubernetes = {};
    git.url = "ssh://git@github.com/schradert/dotfiles";
    git.branch = "trunk";
    git.ssh = {
      username = "git";
      private_key = "\${ tls_private_key.flux.private_key_pem }";
    };
  };
  resource.flux_bootstrap_git.prod = {path = "src/nux/clusters/${config.locals.cluster.name}";};
}
