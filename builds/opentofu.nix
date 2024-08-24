{
  self,
  nix,
  ...
}:
with nix; {
  flake.lib.nixToEnv = flip pipe [
    toUpper
    (replaceStrings ["." "-"] ["__" "_"])
  ];
  perSystem = {config, ...}: {
    options.dotfiles.opentofu.passwords = mkOption {
      type = attrsOf (attrsOf anything);
      default = {};
    };
    config.canivete.opentofu.workspaces.${config.canivete.kubenix.clusters.prod.opentofuWorkspace} = {
      plugins = ["opentofu/random"];
      modules.passwords.resource = mkMerge (flip mapAttrsToList config.dotfiles.opentofu.passwords (name: cfg: {
        random_password.${name} = cfg;
        null_resource.kubernetes.depends_on = ["random_password.${name}"];
        null_resource.kubernetes.provisioner.local-exec.environment.${self.lib.nixToEnv name} = "\${ random_password.${name}.result }";
      }));
    };
  };
}
