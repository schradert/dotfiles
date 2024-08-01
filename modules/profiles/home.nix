{
  config,
  nix,
  ...
}:
with nix; let
  inherit (config.canivete.people) users;
in {
  canivete.deploy.system.homeModules.home-defaults = {config, ...}: {
    home.sessionVariables.XDG_RUNTIME_DIR = "${config.home.homeDirectory}/.run";
  };
  canivete.deploy.darwin.homeModules.home-defaults = {config, ...}: {
    home.homeDirectory = "/home/${config.home.username}";
  };
  canivete.deploy.nixos.modules.home-defaults = {
    home-manager.users = flip mapAttrs users (username: _: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };
    });
  };
}
