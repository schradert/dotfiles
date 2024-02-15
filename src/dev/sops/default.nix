{config, inputs, nix, ...}: with nix; let
  get_age_key_file = pkgs: let
    base_dir = if pkgs.stdenv.isDarwin then "Users" else "home";
    config_dir = if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
  in "/${base_dir}/${config.people.me}/${config_dir}/sops/age/keys.txt";
in {
  flake.homeModules.sops = {pkgs, ...}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];
    sops.age.keyFile = toPath (get_age_key_file pkgs);
  };
  flake.terranixModules.sops = {pkgs, ...}: with pkgs; {
    data.external.sops_decrypt.program = execBash ''
      root="$(${getExe git} rev-parse --show-toplevel)"
      ${getExe sops} --config "$root/.sops.yaml" --decrypt "$root/src/dev/sops/default.yaml" | ${getExe yq}
    '';
  };
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    key_name = "$USER";
    ssh_key_file = "$HOME/.ssh/${key_name}";
    sops_repo_file = "src/dev/sops/${key_name}";
  in {
    packages.keygen = pkgs.mkShellApplication {
      name = "setup";
      text = ''
        age_key_file="${get_age_key_file pkgs}"
        mkdir -p "$(dirname "$age_key_file")"

        ${pkgs.ssh}/bin/ssh-keygen -t ed25519 -P "" -f "${ssh_key_file}" &> /dev/null
        ${nix.getExe pkgs.ssh-to-age} -private-key -i "${ssh_key_file}" > "$age_key_file" 2> /dev/null
        age_key_public="$(${pkgs.age}/bin/age-keygen -y "$get_age_key_file")"

        printf "%s\n" -<<EOT
            Your public age key is $age_key_public

            Ensure the following in .sops.yaml before running 'nix run .#encrypt':

            keys:
              - &${key_name} $age_key_public
            creation_rules:
              - path_regex: ${sops_repo_file}$
                key_groups:
                  - age:
                      - *${key_name}
EOT
      '';
    };
    packages.encrypt = pkgs.mkShellApplication {
      name = "encrypt";
      text = ''
        sops_repo_file="$(${getExe pkgs.git} rev-parse --show-toplevel)/${sops_repo_file}"
        cp "${ssh_key_file}" "$sops_repo_file"
        cp "${ssh_key_file}.pub" "$sops_repo_file.pub"
        ${getExe pkgs.sops} --encrypt --in-place "$sops_repo_file"
      '';
    };
    devShells.sops = pkgs.mkShell {
      packages = [pkgs.sops];
    };
  };
}
