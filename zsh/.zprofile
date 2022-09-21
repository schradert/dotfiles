_brew_pre=$([[ $(uname -s) == "Linux" ]] && echo "/home/linuxbrew/.linuxbrew" || echo "/opt/homebrew")
eval "$("$_brew_pre/bin/brew" shellenv)"

