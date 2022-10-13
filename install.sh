#!/usr/bin/env bash

work_d=$(pwd)
today=$(date +"%Y%m%d")

config_d="$HOME/.config/dotfiles"
backups_d="$config_d/backups"
backup_d="$backups_d/$today"
mkdir -p "$backup_d"
log_f="$backup_d/run.log"

sub() {
    local i o dir
    local "${@}"

    out="${o:-$(basename "$i")}"
    [[ -d $i ]] && {
        local dir="/"
            mkdir -p "$HOME/$out"
            mkdir -p "$backup_d/$out"
        }
        mkdir -p "$(dirname "$backup_d/$out")"

        rsync -iarvz --ignore-existing "$HOME/$out$dir" "$backup_d/$out" | grep -E "^>" | tee -a "$log_f"
        rsync -iarvz --exclude "**/*.swp" "$work_d/$i$dir" "$HOME/$out" | grep -E "^>" | tee -a "$log_f"
    }

    sub i=zsh/.zshrc
    sub i=zsh/.zprofile
    sub i=zsh/.p10k.zsh
    sub i=zsh/config.d o=.config/zsh/config.d
    sub i=gh o=.config/gh
    sub i=git/.gitconfig
    sub i=glab o=.config/glab-cli
    sub i=htop o=.config/htop
    sub i=vim/.vimrc
    sub i=ranger o=.config/ranger
    sub i=thefuck o=.config/thefuck
    sub i=wtf o=.config/wtf
    sub i=nix/.nix-channels
    sub i=nix/darwin-configuration.nix o=.nixpkgs/darwin-configuration.nix
    sub i=nix/nix.conf o=.config/nix/nix.conf

