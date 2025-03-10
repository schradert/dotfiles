{
  perSystem.canivete.pre-commit.settings.hooks.lychee.toml.exclude = ["https://kubernetes-sigs.github.io/node-feature-discovery/charts"];
  # [ ] [node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)
  perSystem.canivete.kubenix.helm.node-feature-discovery = {
    namespace = "kube-system";
    chart = {
      repo = "https://kubernetes-sigs.github.io/node-feature-discovery/charts";
      chart = "node-feature-discovery";
      version = "0.16.4";
      sha256 = "vUXTzMMWUOeYqbkglYOw9ylrXpvlDPHsc+tXDnxCqow=";
    };
    values.prometheus.enable = true;
  };
}
