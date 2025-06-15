{inputs, ...}: {
  # TODO is there a better way to add these things?!
  dotfiles = {config, lib, ...}: let
    inherit (lib) mkOption types mkForce mkIf;
    inherit (types) submodule attrsOf;
    keyFile = "/root/.config/sops/age/keys.txt";
  in {
    config.nixos.sops.age.keyFile = mkForce keyFile;
    options.nodes = mkOption {
      type = attrsOf (submodule ({name, ...}: {
        opentofu = {pkgs, ...}: {
          module."nixos_${name}_system_install" = {
            depends_on = mkIf (name != config.root) ["shell_script.headscale_pre_auth_key-main"];
            extra_environment.SOPS_BIN = "\${ local.SOPS_BIN }";
            extra_environment.SOPS_DIR = "\${ local.SOPS_DIR }";
            extra_files_script = toString (pkgs.writeShellScript "extra-files-script" ''
              key_f="$(pwd)${keyFile}"
              mkdir -p "$(dirname "$key_f")"
              pushd ${inputs.self}
              $SOPS_BIN --decrypt "$SOPS_DIR/me.txt" >"$key_f"
              popd
              chmod 400 "$key_f"
            '');
          };
        };
      }));
    };
  };
}
