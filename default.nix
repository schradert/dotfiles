{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (config.canivete.meta) root domain;
in {
  flake.dotfiles = lib.mapAttrs (_: lib.getAttr "dotfiles") config.allSystems;
  flake.overlays.nur = inputs.nur.overlays.default;
  canivete.meta = {
    domain = "trdos.me";
    root = "sirver";
    people.me = "tristan";
    people.users.tristan = {
      name = "Tristan Schrader";
      accounts.github = "schradert";
      accounts.gitlab = "schrader.tristan";
      profiles.default.email = "t0rdos@pm.me";
    };
  };
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.default = pkgs.wrapFlags config.canivete.opentofu.script "--add-flags \"--workspace deploy\"";
    canivete.pre-commit.languages.shell.enable = true;
    canivete.kubenix.clusters.prod.deploy.fetchKubeconfig = "ssh ${root} sudo k3s kubectl config view --raw | sed 's/127\.0\.0\.1/${domain}/'";
    # URLs built with substitution
    # TODO error: repetition quantifier expects a valid decimal: "^.+\${.+}.+$"
    # canivete.pre-commit.settings.hooks.lychee.settings.toml.exclude = [];
  };
}
