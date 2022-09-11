#!/usr/bin/env bash

set -eux

work_d=$(pwd)
today=$(date +"%Y%m%d")

config_d="$HOME/.config/dotfiles"
backups_d="$config_d/backups"
backup_d="$backups_d/$today"
mkdir -p $backup_d
log_f="$backup_d/run.log"

sub() {
    local i o
    local "${@}"

    [[ -d $i ]] && dir="/"
    out="${o:-`basename $i`}"
    rsync -arvz --progress --ignore-existing "$HOME/$out$dir" "$backup_d/$out" | tee -a $log_f
    rsync -arvz --progress --exclude "**/*.swp" "$work_d/$i$dir" "$HOME/$out" | tee -a $log_f
}

sub i=zsh/.zshrc
sub i=zsh/.zprofile
sub i=zsh/.p10k.zsh
sub i=zsh/config.d o=.config/zsh/config.d
sub i=gh o=.config/gh
sub i=git/.gitconfig
sub i=glab o=.config/glab-cli
sub i=htop o=.config/htop


