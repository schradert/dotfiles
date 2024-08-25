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
    lib,
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
    options.dotfiles.${name}.enable = lib.mkEnableOption name;
    config = lib.mkIf config.dotfiles.${name}.enable {
      home-manager.users.${me} = {config, ...}: {
        systemd.user.services.${name} = {
          Install.WantedBy = ["default.target"];
          Unit.Requires = ["secrets.service" "ssh-agent.service"];
          Unit.After = ["secrets.service" "ssh-agent.service"];
          Service.Restart = "on-failure";
          Service.WorkingDirectory = "${config.xdg.dataHome}/devops";
          Service.ExecStart = lib.getExe script;
        };
      };
    };
  };
}
