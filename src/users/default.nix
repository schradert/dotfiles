{
  config,
  lib,
  pkgs,
  ...
}: let
  sshKeySubmodule = lib.types.submodule {
    options = {
      public = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc "Contents of public key";
        example = "ssh-ed25519 AAAAC3Qrst1lZDI1NTE5AAAAIBRaIPhp5LExmqK7KECgbqdTY3goyUfNgKjKD9WFalkE";
      };
    };
  };
  userSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "The name of the user to default to in all contexts";
        example = "John Doe";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc "The default email to associate with the user in all contexts";
        example = "me@123.com";
      };
      sshKeys = lib.mkOption {
        type = lib.types.attrsOf sshKeySubmodule;
        description = lib.mdDoc "Public and private keys for SSH access between machines";
      };
    };
  };
  peopleSubmodule = lib.types.submodule {
    options = {
      users = lib.mkOption {
        type = lib.types.attrsOf userSubmodule;
        description = lib.mdDoc "All of the users to create configurations for";
      };
      me = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          The name of the user that represents myself.
          This will be the admin user in all contexts.
        '';
      };
      my = lib.mkOption {
        default = config.people.users.${config.people.me};
        type = userSubmodule;
        description = lib.mdDoc "The user details associated with 'me'";
      };
    };
  };
in {
  imports = [./config.nix];
  options.people = lib.mkOption {type = peopleSubmodule;};
}
