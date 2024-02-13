{inputs, ...}: {
  imports = [inputs.nixos-flake.flakeModule];
  perSystem = {
    config,
    nix,
    pkgs,
    self',
    ...
  }: with nix; {
    packages.default = pkgs.writeShellApplication {
      name = "dotfiles";
      # We override the ControlPath because otherwise Nix will create too long of a Unix domain socket name
      # if the name of the device is more than 5 characters... This path is managed by nix and will be deleted
      # when the connection to the remote host ends when the program halts.
      text = ''
        export NIX_SSHOPTS="-o ControlPath=/tmp/%C"
        ${concatStringsSep "\n" (forEach (attrNames inputs.self.nixosConfigurations) (hostname: ''
          ${getExe pkgs.nixos-rebuild} test \
            --flake .#${hostname} \
            --build-host ${hostname} \
            --target-host ${hostname} \
            --use-remote-sudo \
            --fast
        ''))}
        ${optionalString pkgs.stdenv.isDarwin ''
          ${getExe self'.packages.activate}
          ${getExe self'.packages.activate-home}
        ''}
      '';
    };
    devShells.default = pkgs.mkShell {
      inputsFrom = attrValues (removeAttrs config.devShells ["default"]);
    };
  };
}
