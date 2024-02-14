{nix, ...}: with nix; let
  option = mkOption {
    type = str;
    description = mdDoc "The hostname of the relevant machine";
    example = "another-server";
  };
in {
  flake.nixosModules.hostname = {config, ...}: {
    options.dotfiles.hostname = option;
    config.networking.hostName = config.dotfiles.hostname;
  };
  flake.homeModules.hostname.options.dotfiles.hostname = option;
  flake.homeModules.ssh = home: let
    user = home.config.home.username;
  in {
    programs.ssh.enable = true;
    programs.ssh.forwardAgent = true;
    sops.secrets.ssh = {
      format = "binary";
      sopsFile = ./dev/sops + "/${user}";
    };
    # TODO still not working
    # home.file.".ssh/${user}".source = home.config.sops.secrets.ssh.path;
    home.file.".ssh/${user}.pub".source = ./dev/sops + "/${user}.pub";
  };
}
