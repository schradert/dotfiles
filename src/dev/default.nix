{inputs, ...}: {
  imports = [inputs.nixos-flake.flakeModule];
  perSystem = {
    config,
    nix,
    pkgs,
    self',
    ...
  }:
    with nix; {
      packages.default = pkgs.writeShellApplication {
        name = "dotfiles";
        # We override the ControlPath because otherwise Nix will create too long of a Unix domain socket name
        # if the name of the device is more than 5 characters... This path is managed by nix and will be deleted
        # when the connection to the remote host ends when the program halts.
        text = ''
          ${getExe self'.packages.terranix-deploy}
          ${
            if pkgs.stdenv.isDarwin
            then ''
              ${getExe self'.packages.activate}
              ${getExe self'.packages.activate-home}
            ''
            else ''
              export NIX_SSHOPTS="-o ControlPath=/tmp/%C"
              ${concatStringsSep "\n" (forEach (attrNames inputs.self.nixosConfigurations) (hostname: ''
                extraBuildFlags=()
                if [[ $(hostname) != ${hostname} ]]; then
                  extraBuildFlags+=(
                    --build-host ${hostname}
                    --target-host ${hostname}
                    --use-remote-sudo
                  )
                fi
                sudo ${getExe pkgs.nixos-rebuild} switch --flake .#${hostname} "''${extraBuildFlags[@]}"
              ''))}
            ''
          }
        '';
      };
      devShells.default = pkgs.mkShell {
        inputsFrom = attrValues (removeAttrs config.devShells ["default"]);
      };
    };
}
