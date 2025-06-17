{inputs, ...}: {
  dotfiles = {canivete, config, lib, ...}: let
    keyFile = "/home/${config.me}/.config/sops/age/keys.txt";
  in {
    config.nixos.sops.age.keyFile = lib.mkForce keyFile;
    options.nodes = canivete.mkNestedSubmodule ({name, ...}: {
      opentofu = {pkgs, ...}: {
        module."nixos_${name}_system_install" = {
          extra_environment.SOPS_BIN = "\${ local.SOPS_BIN }";
          extra_environment.SOPS_DIR = "\${ local.SOPS_DIR }";
          extra_files_script = toString (pkgs.writeShellScript "extra-files-script" ''
            key_f="$(pwd)${keyFile}"
            mkdir -p "$(dirname "$key_f")"
            pushd ${inputs.self}
            $SOPS_BIN --decrypt "$SOPS_DIR/${config.me}.txt" >"$key_f"
            popd
            chmod 400 "$key_f"
            chown -R ${config.me}:users /home/${config.me}
          '');
        };
      };
    });
  };
}
