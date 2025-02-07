{
  # TODO self-hosted matrix server (dendrite, synapse, etc.)
  canivete.deploy.system.homeModules.matrix = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.dotfiles.profiles.chat.enable {
      home.packages = [pkgs.iamb];
    };
  };
}
