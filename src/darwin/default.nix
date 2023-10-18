{ self, config, ... }:
{
  flake = {
    darwinModules.common = {
      users.users.${config.people.myself} = {};
      home-manager.users.${config.people.myself} = {
        imports = [
          self.darwinModules.home-manager
          self.homeModules.darwin-graphical
        ];
      };
      system.stateVersion = 4;
    };
  };
}
