{
  canivete,
  config,
  lib,
  ...
}: {
  canivete.deploy.nodes = lib.flip lib.mapAttrs config.dotfiles.nodes (_: modules: {
    profiles.system.canivete = {inherit (modules) opentofu;};
  });
  dotfiles = _: {
    options.nodes = canivete.mkNestedSubmodule {
      options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
    };
    options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
    config.opentofu = {
      plugins = ["linyinfeng/shell"];
      modules = {pkgs, ...}: {
        provider.shell.interpreter = [(lib.getExe pkgs.bash) "-c"];
      };
    };
  };
  perSystem.canivete.opentofu.workspaces = {
    bootstrap.encryptedState.enable = false;
    deploy = _: {imports = [config.dotfiles.opentofu];};
  };
}
