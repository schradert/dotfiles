{
  canivete.deploy.nodes.morgenmuffel = {
    canivete.os = "macos";
    profiles.system.canivete.configuration = {
      dotfiles.workstation.enable = true;
      homebrew.casks = ["zotero"];
    };
    profiles.tristan.canivete.type = "home-manager";
    profiles.tristan.canivete.configuration = {node, ...}: let
      # TODO is there general logic here I can use?
      inherit (node.config.profiles) system;
      module.options.dotfiles = system.options.dotfiles;
      module.config.dotfiles = system.config.dotfiles;
    in {
      imports = [module];
      dotfiles.services.raycast.enable = true;
      home.stateVersion = "23.05";
    };
  };
}
