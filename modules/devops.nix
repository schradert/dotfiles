{
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  name = "devops";
  inherit (config.canivete.people) me my;
  full_name = my.name;
  inherit (my.profiles.default) email;
  dir = "/var/lib/${name}";
  url = "git@github.com:schradert/dotfiles";
  branch = "trunk";
in {
  canivete.deploy.nixos.modules.${name} = {
    config,
    lib,
    pkgs,
    ...
  }: let
    script = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [git openssh];
      text = ''
        set -euo pipefail

        echo "${fileContents (inputs.self + "/.canivete/sops/${me}.pub")}" > ~/.ssh/${name}.pub
        cp -f /canivete/secrets/data.external.age-me ~/.config/sops/age/keys.txt
        cp -f "/canivete/secrets/data.external.ssh-key-${me}" ~/.ssh/${name}

        git config user.name "${full_name}"
        git config user.email ${email}
        ssh-add ~/.ssh/${name}

        while true; do
            remoteHash=$(git ls-remote ${url} ${branch} | awk '{print $1}')
            localHash=$([[ -d ".git" ]] && git rev-parse HEAD || echo "null")
            if [[ "$remoteHash" != "$localHash" ]]; then
                rm -rf ./*
                git clone --depth 1 --branch ${branch} ${url} .
                nix run . -- -auto-approve
                git add .
                git commit --gpg-sign --amend --force-with-lease --no-edit
            fi
            sleep 60
        done

      '';
    };
  in {
    options.dotfiles.${name}.enable = lib.mkEnableOption name;
    config = lib.mkIf config.dotfiles.${name}.enable {
      users.users.${name} = {
        createHome = true;
        isSystemUser = true;
        group = "root";
      };
      systemd.tmpfiles.rules = ["d ${dir} 0700 ${name} root - -"];
      systemd.services.${name} = {
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          User = name;
          Restart = "on-failure";
          WorkingDirectory = dir;
          ExecStart = lib.getExe script;
        };
      };
    };
  };
}
