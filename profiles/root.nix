{
  config,
  nix,
  ...
}:
with nix; {
  options.root = mkOption {
    type = enum (attrNames config.nixos);
    example = "my-nixos-server";
    description = "NixOS machine to use as a root server for secret storage";
  };
  config.perSystem.canivete.opentofu.workspaces.cloud = {
    plugins = ["Backblaze/b2"];
    modules.backblaze = {
      provider.b2 = {
        application_key = vals.sops "default.yaml#/backblaze/application_key";
        application_key_id = vals.sops "default.yaml#/backblaze/application_key_id";
      };
      resource.b2_bucket.main = {
        bucket_name = "t0rdos";
        bucket_type = "allPrivate";
      };
    };
  };
  config.flake.homeModules.sshfs = {
    config,
    flake,
    lib,
    pkgs,
    ...
  }: let
    inherit (flake.config) root;
    host = flake.config.nixos.${root}.ssh.hostname;
    Where = "/mnt/${root}";
    What = "${host}:${Where}";
    name = replaceStrings ["/"] ["-"] (substring 1 (stringLength Where) Where);
  in {
    config = with lib;
      mkMerge [
        (mkIf (config.dotfiles.hostname == root) {
          systemd.user.mounts.${name} = {
            Install.WantedBy = ["default.target"];
            Unit.Description = "Mount code in root's /mnt";
            Mount.Where = Where;
            Mount.What = "${config.home.homeDirectory}/dotfiles";
          };
        })
        (mkIf (config.dotfiles.hostname != root) (mkMerge [
          (mkIf pkgs.stdenv.isLinux {
            systemd.user.mounts.${name} = {
              Install.WantedBy = ["default.target"];
              Unit.Description = "SSHFS mount to root server";
              Unit.Wants = ["network-online.target"];
              Unit.After = ["network-online.target"];
              Mount = {
                inherit What Where;
                Type = "fuse.sshfs";
                # Automounting user mounts currently not supported because they require root privileged
                # Options = "x-systemd.automount";
              };
            };
          })
          (mkIf pkgs.stdenv.isDarwin {
            launchd.agents.${name} = {
              enable = true;
              config.RunAtLoad = true;
              config.KeepAlive = true;
              config.ProgramArguments = ["${pkgs.sshfs-fuse}/bin/sshfs" What];
            };
          })
        ]))
      ];
  };
}
