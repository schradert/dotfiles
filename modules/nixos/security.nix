{inputs, ...}: {
  dotfiles = {config, lib, ...}: let
    inherit (config) me;
    key = lib.fileContents (inputs.self + "/.canivete/sops/${me}.pub");
  in {
    nixos = {lib, ...}: {
      security.sudo.extraRules = [
        {
          groups = ["wheel"];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
      services.openssh.enable = true;
      # NOTE currently necessary for sops-install-secrets to exist instead of a system activation script
      # TODO should this go upstream? worth checking how stable this is and community commentary thereof
      services.userborn.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [key];
      users.users.${me} = {
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = [key];
      };
    };
  };
}
