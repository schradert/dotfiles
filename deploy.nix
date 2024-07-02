{
  config,
  inputs,
  nix,
  ...
}: {
  options.flake.deploy = with nix; mkOption {type = lazyAttrsOf anything;};
  config.flake = {
    deploy = {
      nodes.sirver = {
        hostname = "sirver";
        profilesOrder = ["system" "home-tristan"];
        profiles.system = {
          user = "root";
          sshUser = "tristan";
          sshOpts = ["-J" config.domain];
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.sirver;
          remoteBuild = true;
        };
        # profiles.home-tristan = {
        #   user = "tristan";
        #   sshUser = "tristan";
        #   sshOpts = ["-J" config.domain];
        #   path = inputs.deploy-rs.lib.x86_64-linux.activate.home-manager inputs.self.legacyPackages.x86_64-linux.homeConfigurations.sirver;
        #   remoteBuild = true;
        # };
      };
      nodes.chilldom = {
        hostname = "chilldom";
        profilesOrder = ["system" "home-tristan"];
        profiles.system = {
          user = "root";
          sshUser = "tristan";
          sshOpts = ["-J" config.domain];
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.chilldom;
          remoteBuild = true;
        };
        # profiles.home-tristan = {
        #   user = "tristan";
        #   sshUser = "tristan";
        #   sshOpts = ["-J" config.domain];
        #   path = inputs.deploy-rs.lib.x86_64-linux.activate.home-manager inputs.self.legacyPackages.x86_64-linux.homeConfigurations.chilldom;
        #   remoteBuild = true;
        # };
      };
      nodes.morgenmuffel = {
        hostname = "localhost";
        # hostname = "morgenmuffel";
        profilesOrder = ["system" "home-tristan"];
        profiles.system = {
          user = "root";
          # sshUser = "tristan";
          # sshOpts = ["-J" "localhost"];
          path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin inputs.self.darwinConfigurations.morgenmuffel;
          # remoteBuild = true;
        };
        profiles.home-tristan = {
          user = "tristan";
          # sshUser = "tristan";
          # sshOpts = ["-J" "localhost"];
          path = inputs.deploy-rs.lib.aarch64-darwin.activate.home-manager inputs.self.legacyPackages.aarch64-darwin.homeConfigurations.tristan;
          # path = inputs.deploy-rs.lib.x86_64-linux.activate.home-manager inputs.self.legacyPackages.x86_64-linux.homeConfigurations.morgenmuffel;
          remoteBuild = true;
        };
      };
    };
  };
}
