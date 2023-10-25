{ ... }:
{
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
      climax-vps = {
        hostname = "vps.nodes.climax.bio";
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
    };
  };
}
