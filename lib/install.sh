#!@bash@
if [[ -e /etc/nixos ]]; then
  sudo nixos-rebuild test --flake '.#'
else
  nix build .#darwinConfigurations.morgenmuffel.system
  ./result/sw/bin/darwin-rebuild switch --flake .
fi
