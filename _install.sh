#!/usr/bin/env bash

host="$(hostname)"
host="${host%.*}"
if [[ -f /etc/NIXOS ]]; then
  nix build ".#nixosConfigurations.$host"
  ./result/bin/nixos-rebuild switch --flake .
elif [[ $(uname) == Darwin ]]; then
  nix build ".#darwinConfigurations.$host".system
  ./result/sw/bin/darwin-rebuild switch --flake .
else
  nix build ".#homeConfigurations.$(whoami)"
  ./result/activate
fi

