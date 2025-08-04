{inputs, ...}: {
  dotfiles = {
    canivete,
    config,
    lib,
    ...
  }: let
    keyFile = "/home/${config.me}/.config/sops/age/keys.txt";
  in {
    config.nixos.sops.age.keyFile = lib.mkForce keyFile;
    config.home-manager = {pkgs, ...}: {
      programs.doom-emacs = {
        extraBinPackages = [pkgs.sops];
        tangle.packages = ''
          (package! sops :recipe (:host github :repo "djgoku/sops") :pin "afeb1232b89335d77a3f4b6639ebe8a2b70fae3f")
        '';
        tangle.config = ''
          (use-package! sops
            :init
            (global-sops-mode 1)

            :config
            (defvar sops-mode-map (make-sparse-keymap) "Keymap for sops-mode.")
            (map! :map sops-mode-map
                  :localleader
                  "fe" #'sops-edit-file
                  "fc" #'sops-cancel
                  "fs" #'sops-save-file)

            ;; Activate keymap in sops-mode
            (add-hook! sops-mode (set-keymap-parent sops-mode-map (current-local-map))))
        '';
      };
    };
    options.nodes = canivete.mkNestedSubmodule ({name, ...}: {
      opentofu = {pkgs, ...}: {
        module."nixos_${name}_system_install" = {
          extra_environment.SOPS_BIN = "\${ local.SOPS_BIN }";
          extra_environment.SOPS_DIR = "\${ local.SOPS_DIR }";
          # FIXME chown doesn't seem to work below...
          extra_files_script = toString (pkgs.writeShellScript "extra-files-script" ''
            key_f="$(pwd)${keyFile}"
            mkdir -p "$(dirname "$key_f")"
            pushd ${inputs.self}
            $SOPS_BIN --decrypt "$SOPS_DIR/${config.me}.txt" >"$key_f"
            popd
            chmod 400 "$key_f"
            chown -R ${config.me}:users "$(pwd)/home/${config.me}"
          '');
        };
      };
    });
  };
}
