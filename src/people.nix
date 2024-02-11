{
  config,
  nix,
  ...
}:
with nix; let
  sshKeySubmodule = submodule {
    options = {
      public = mkOption {
        type = str;
        description = mdDoc "Contents of public key";
        example = "ssh-ed25519 AAAAC3Qrst1lZDI1NTE5AAAAIBRaIPhp5LExmqK7KECgbqdTY3goyUfNgKjKD9WFalkE";
      };
    };
  };
  userSubmodule = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "The name of the user to default to in all contexts";
        example = "John Doe";
      };
      email = mkOption {
        type = str;
        description = mdDoc "The default email to associate with the user in all contexts";
        example = "me@123.com";
      };
      accounts = mkOption {
        type = attrsOf str;
        default = {};
        example.github = "my-username";
        description = mdDoc "Mapping of external program name to user account name on it";
      };
      sshKeys = mkOption {
        type = attrsOf sshKeySubmodule;
        description = mdDoc "Public and private keys for SSH access between machines";
      };
    };
  };
in {
  options.people = mkOption {
    type = submodule {
      options = {
        users = mkOption {
          type = attrsOf userSubmodule;
          description = mdDoc "All of the users to create configurations for";
        };
        me = mkOption {
          type = str;
          description = mdDoc ''
            The name of the user that represents myself.
            This will be the admin user in all contexts.
          '';
        };
        my = mkOption {
          default = config.people.users.${config.people.me};
          type = userSubmodule;
          description = mdDoc "The user details associated with 'me'";
        };
      };
    };
  };
}
