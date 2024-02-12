{
  config,
  nix,
  ...
}:
with nix; let
  option = mkOption {
    type = str;
    description = mdDoc "The hostname of the relevant machine with this user";
    example = "another-server";
  };
in {
  flake.nixosModules.nixos-hostname = nixos: {
    options.dotfiles.hostname = option;
    config.networking.hostName = nixos.config.dotfiles.hostname;
  };
  flake.darwinModules_.darwin-hostname = nixos: {
    options.dotfiles.hostname = option;
    config.networking.hostName = nixos.config.dotfiles.hostname;
  };
  flake.homeModules.ssh = home: let
    base = home.config.home.homeDirectory;
  in {
    config = mkMerge [
      {
        programs.ssh = {
          enable = mkDefault true;
          forwardAgent = true;
          matchBlocks = {
            climax-static-relay = {
              hostname = "35.212.163.7";
              user = "root";
              identityFile = "${base}/.ssh/climax_server";
            };
            climax-server-via-relay = {
              proxyCommand = "ssh -q climax-static-relay nc localhost 2222";
              user = "tristan";
              identityFile = "${base}/.ssh/climax_server";
            };
            climax-dev = {
              hostname = "dev.nodes.climax.bio";
              user = "terraform";
              identityFile = "${base}/.ssh/terraform";
            };
            climax-relay = {
              hostname = "relay.nodes.climax.bio";
              user = "terraform";
              identityFile = "${base}/.ssh/terraform";
            };
            climax-server = {
              hostname = "server.nodes.climax.bio";
              user = "terraform";
              identityFile = "${base}/.ssh/terraform";
            };
            sirver = {
              hostname = "192.168.50.21";
              user = "tristan";
              identityFile = "${base}/.ssh/tristan_sirver_ed25519";
            };
          };
        };
      }
      (mkIf home.config.programs.ssh.enable {
        # TODO (Tristan): figure out how I can get the path to work properly with home-manager
        sops.secrets."ssh/${config.people.me}/github" = {};
        # home.file.".ssh/github".source = config.sops.secrets."ssh/${flake.config.people.me}/github".path;
        home.file.".ssh/github.pub".text = let
          key = config.people.my.sshKeys.github.public;
          username = home.config.home.username;
          hostname = home.config.dotfiles.hostname;
        in "${key} ${username}@${hostname}.local";
      })
    ];
  };
}
