{
  self,
  config,
  ...
}: {
  flake = {
    darwinModules.common = {
      users.users.${config.people.me} = {};
      home-manager.users.${config.people.me} = {
        imports = [
          self.darwinModules.home-manager
          self.homeModules.darwin-graphical
        ];
      };
      system.stateVersion = 4;
    };
  };
}
