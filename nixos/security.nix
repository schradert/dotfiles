{inputs, ...}: {
  dotfiles.nixos = {lib, ...}: let
    key = lib.fileContents (inputs.self + "/.canivete/sops/tristan.pub");
  in {
    security.sudo.extraRules = [
      {
        users = ["tristan"];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    services.openssh.enable = true;
    services.userborn.enable = true;
    users.mutableUsers = true;
    users.users.root.openssh.authorizedKeys.keys = [key];
    users.users.tristan.openssh.authorizedKeys.keys = [key];
  };
}
