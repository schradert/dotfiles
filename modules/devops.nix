{
  config,
  inputs,
  nix,
  ...
}:
with nix; let
  name = "devops";
  url = "git@github.com:schradert/dotfiles";
  branch = "trunk";
  inherit (config.canivete.people) me;
in {
  canivete.deploy.nixos.modules.${name} = {
    config,
    pkgs,
    ...
  }: let
    script = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [git openssh];
      text = ''
        set -euo pipefail
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
    options.dotfiles.${name}.enable = mkEnableOption name;
    config = mkIf config.dotfiles.${name}.enable {
      systemd.services.${name} = {
        wantedBy = ["default.target"];
        script = getExe script;
        requires = ["secrets.service" "ssh-agent.service"];
        after = ["secrets.service" "ssh-agent.service"];
        serviceConfig.Restart = "on-failure";
        serviceConfig.WorkingDirectory = "${config.home-manager.users.${me}.xdg.dataHome}/devops";
        serviceConfig.User = me;
      };
    };
  };
}
