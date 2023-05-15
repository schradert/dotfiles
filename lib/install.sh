#!@bash@
if [[ -e /etc/nixos ]]; then
  sudo nixos-rebuild test --flake '.#'
else
  nix run "$(pwd)#homeConfigurations.tristanschrader.activationPackage"
fi
