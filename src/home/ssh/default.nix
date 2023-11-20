{
  config,
  flake,
  lib,
  ...
}: {
  options.hostname = lib.mkOption {
    type = lib.types.str;
    description = lib.mdDoc "The hostname of the relevant machine with this user";
    example = "another-server";
  };
  config = {
  programs.ssh = {
    enable = true;
    forwardAgent = true;
    matchBlocks = {
      climax-static-relay = {
        hostname = "35.212.163.7";
        user = "root";
        identityFile = "/Users/tristanschrader/.ssh/climax_server";
      };
      climax-server-via-relay = {
        proxyCommand = "ssh -q climax-static-relay nc localhost 2222";
        user = "tristan";
        identityFile = "/Users/tristanschrader/.ssh/climax_server";
      };
      climax-dev = {
        hostname = "dev.nodes.climax.bio";
        user = "terraform";
        identityFile = "/Users/tristanschrader/.ssh/terraform";
      };
      climax-relay = {
        hostname = "relay.nodes.climax.bio";
        user = "terraform";
        identityFile = "/Users/tristanschrader/.ssh/terraform";
      };
      climax-server = {
        hostname = "server.nodes.climax.bio";
        user = "terraform";
        identityFile = "/Users/tristanschrader/.ssh/terraform";
      };
      sirver = {
        hostname = "192.168.50.21";
        user = "tristan";
        identityFile = "/Users/tristanschrader/.ssh/tristan_sirver_ed25519";
      };
    };
  };

  # TODO (Tristan): figure out how I can get the path to work properly with home-manager
  sops.secrets."ssh/${flake.config.people.me}/github" = {};
  # home.file.".ssh/github".source = config.sops.secrets."ssh/${flake.config.people.me}/github".path;
  home.file.".ssh/github.pub".text = "${flake.config.people.my.sshKeys.github.public} ${config.home.username}@${config.hostname}.local";
  };
}
