{canivete, config, lib, ...}: let
  inherit (lib) flip mapAttrs mkDefault mkOption types getExe;
in {
  canivete.deploy.nodes = flip mapAttrs config.dotfiles.nodes (_: modules: {
    profiles.system.canivete = {inherit (modules) opentofu;};
  });
  dotfiles = {...}: {
    options.nodes = canivete.mkNestedSubmodule ({config, name, ...}: {
      options.install_host = canivete.mkNullableOption types.str {description = "Initial installation target";};
      options.opentofu = canivete.mkModuleOption {description = "Common OpenTofu configuration";};
      config.opentofu.module."nixos_${name}_system_install".target_host = mkDefault config.install_host;
    });
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
