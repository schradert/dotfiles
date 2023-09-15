#!\bash
if [[ -e /etc/nixos ]]; then
  sudo nixos-rebuild test --flake '.#'
else
  nix run "$(pwd)#homeConfigurations.tristanschrader.activationPackage"
  # Install other things that can't be managed by nix
  # SPICETIFY
  # It doesn't seem like this tool is mature enough in nix to work properly (spicetify-cli can't detect anything).
# [ ! -d ~/.config/spicetify ] && curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
fi
