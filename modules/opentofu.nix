{canivete, config, lib, ...}: let
  inherit (lib) flip mapAttrs mkOption types getExe;
in {
  canivete.deploy.nodes = flip mapAttrs config.dotfiles.nodes (_: modules: {
    profiles.system.canivete = {inherit (modules) opentofu;};
  });
  dotfiles = {...}: {
    options.nodes = canivete.mkNestedSubmodule {
      options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
    };
    options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
    config.opentofu = {
      plugins = ["linyinfeng/shell"];
      modules = {pkgs, ...}: {
        provider.shell.interpreter = [(getExe pkgs.bash) "-c"];
      };
    };
  };
  perSystem.canivete.opentofu.workspaces.deploy = {...}: {
    imports = [config.dotfiles.opentofu];
  };
}
