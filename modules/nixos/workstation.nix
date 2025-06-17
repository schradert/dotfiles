{config, inputs, lib, ...}: let
  inherit (config.canivete.meta.people) me;
  inherit (lib) mkEnableOption mkForce mkIf toList;
  keyFile = "/home/${me}/.config/sops/age/keys.txt";
in {
  dotfiles = {canivete, ...}: {
    config.nixos = {config, ...}: {
      options.dotfiles.profiles.client.workstation.enable = mkEnableOption "workstation";
      config = mkIf config.dotfiles.profiles.client.workstation.enable {
        assertions = toList {
          assertion = config.dotfiles.profiles.client.enable;
          message = "Workstation is for clients";
        };
        dotfiles.profiles.client.code.enable = true;
        dotfiles.profiles.virtualization.enable = true;
        sops.age.keyFile = mkForce keyFile;
      };
    };
    options.nodes = canivete.mkNestedSubmodule ({name, ...}: {
      config = mkIf (config.canivete.deploy.nodes.${name}.profiles.system.canivete.configuration.config.dotfiles.profiles.client.workstation.enable) {
        opentofu = {pkgs, ...}: {
          module."nixos_${name}_system_install" = {
            extra_environment.SOPS_BIN = "\${ local.SOPS_BIN }";
            extra_environment.SOPS_DIR = "\${ local.SOPS_DIR }";
            extra_files_script = toString (pkgs.writeShellScript "extra-files-script" ''
              key_f="$(pwd)${keyFile}"
              mkdir -p "$(dirname "$key_f")"
              pushd ${inputs.self}
              $SOPS_BIN --decrypt "$SOPS_DIR/${me}.txt" >"$key_f"
              popd
              chmod 400 "$key_f"
            '');
          };
        };
      };
    });
  };
}
