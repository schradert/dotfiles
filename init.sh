#!/bin/bash

# Copy files from host
# ~/.zshrc
# ~/.p10k.zsh
# ~/.fzf.zsh
# ~/.fzf-gcloud.plugin.zsh (remember we had to rewrite this one...)

# TODO setup .tmux.conf
# TODO wtfutil config

# We should probably generate new SSH keys on a different host

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/tristanschrader/.profile
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/tristanschrader/.zprofile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt-get install --yes build-essential fontconfig

# Install brew dependencies
brew install ansible bat cheat darksky-weather direnv exa fzf gh git helm htop hyperfine jq kubernetes-cli lsof navi node operator-sdk ranger rclone ripgrep shellcheck speedtest-cli terraform thefuck tmux virtualenv wget wtfutil xclip zoxide zsh
# We don't install the mattermost cask because it barely works... Mattermost functionality is supported best in the browser unfortunately
brew install mmctl
brew install java
brew install emacs
brew install git-gui
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
brew install --cask kodi
brew install --cask jellyfin
brew install --cask android-studio
brew tap homebrew/command-not-found
/home/linuxbrew/.linuxbrew/opt/fzf/install

# Install docker
sudo apt-get update --yes
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update --yes
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
# Make run without root
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker

mkdir -p ~/.docker/cli-plugins
ln -sfn /home/linuxbrew/.linuxbrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose
DOCKER_BUILDX_LATEST=$(wget -qO- "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r .name)
curl "https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_LATEST/buildx-$DOCKER_BUILDX_LATEST.linux-amd64" \
    -o ~/.docker/cli-plugins/docker-buildx
chmod a+x ~/.docker/cli-plugins/buildx-"$DOCKER_BUILDX_LATEST".linux-amd64

# TODO Must build node from source ???
# TODO how to install docker? brew install --cask docker or just brew install docker?
# if gcloud doesn't exist, brew install --cask google-cloud-sdk
# if we want google drive mount, brew install --cask google-drive
# TODO handle if anything must be built from source, like brew install --build-from-source node

# Install oh-my-zsh and plugins
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install fonts
mkdir -p ~/.local/share/fonts
curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o ~/.local/share/fonts/MesloLGS%20NF%20Regular.ttf
curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o ~/.local/share/fonts/MesloLGS%20NF%20Bold.ttf
curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o ~/.local/share/fonts/MesloLGS%20NF%20Italic.ttf
curl https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o ~/.local/share/fonts/MesloLGS%20NF%20Bold%20Italic.ttf
chmod 0644 ~/.local/share/fonts/MesloLGS%20NF%20Regular.ttf
chmod 0644 ~/.local/share/fonts/MesloLGS%20NF%20Bold.ttf
chmod 0644 ~/.local/share/fonts/MesloLGS%20NF%20Italic.ttf
chmod 0644 ~/.local/share/fonts/MesloLGS%20NF%20Bold%20Italic.ttf
sudo fc-cache -f -v
# Install theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Install plugins
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab"
# TODO should I use fast-syntax-highlighting or zsh-syntax-highlighting?
# git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
git clone https://github.com/chrissicool/zsh-256color.git "$ZSH_CUSTOM/plugins/zsh-256color"
git clone https://github.com/unixorn/git-extra-commands.git "$ZSH_CUSTOM/plugins/git-extra-commands"
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/you-should-use"
git clone https://github.com/DarrinTisdale/zsh-aliases-exa.git "$ZSH_CUSTOM/plugins/zsh-aliases-exa"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-completions.git "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions"
git clone https://github.com/spwhitt/nix-zsh-completions.git "$ZSH_CUSTOM/plugins/nix-zsh-completions"

# Change default shell
sudo chsh "$(whoami)" "$(which zsh)"

# Install nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Google drive mount
sudo apt install software-properties-common
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ocamlfuse.gpg] https://... $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/ocamlfuse.list >/dev/null
curl -fsSL https://.../gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ocamlfuse.gpg
sudo add-apt-repository ppa:alessandro-strada/ppa
sudo apt update --yes
sudo apt install google-drive-ocamlfuse
google-drive-ocamlfuse
mkdir -p /Volumes/GoogleDrive
sudo chown "$USER" -R /Volumes
google-drive-ocamlfuse /Volumes/GoogleDrive

release=$(lsb_release -cs)
pkg_name="google-drive-omcalfuse"
gpg_key="/etc/apt/keyrings/$pkg_name.gpg"
pkg_url="https://launchpad.net/~alessandro-strada/ubuntu/ppa/google-drive-ocamlfuse"
wget -O debian-ocamlfuse.deb https://launchpad.net/~alessandro-strada/+archive/ubuntu/ppa/+files/google-drive-ocamlfuse_0.7.30-0ubuntu1~ubuntu20.04.1_amd64.deb
sudo apt install ./debian-ocamlfuse.deb
rm -f ./debian-ocamlfuse.deb
# Unmounting
# fusermount -u /Volumes/GoogleDrive
#

git config --global pager.branch false


# Spicetify
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh
