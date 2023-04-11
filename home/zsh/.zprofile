_brew_pre=$([[ $(uname -s) == "Linux" ]] && echo "/home/linuxbrew/.linuxbrew" || echo "/opt/homebrew")
eval "$("$_brew_pre/bin/brew" shellenv)"
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi 
