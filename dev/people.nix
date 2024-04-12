{
  config,
  nix,
  ...
}:
with nix; let
  userSubmodule = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "The name of the user to default to in all contexts";
        example = "John Doe";
      };
      accounts = mkOption {
        type = attrsOf str;
        default = {};
        example.github = "my-username";
        description = mdDoc "Mapping of external program name to user account name on it";
      };
      profiles = mkOption {
        type = attrsOf (submodule {
          options.email = mkOption {
            type = str;
            description = mdDoc "The email to associate with the user in this profile";
            example = "me@123.com";
          };
        });
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
