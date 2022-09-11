#!/usr/bin/env bash

work_d=$(pwd)
today=$(date +"%Y%m%d")

config_d="$HOME/.config/dotfiles"
backups_d="$config_d/backups"
backup_d="$backups_d/$today"
mkdir -p $backup_d
log_f="$backup_d/run.log"

sub() {
    local i, o
    local "${@}"

    out="$HOME/$o"
    backup="$backup_d/$(dirname '$o')"
    in="$work_d/$i"

    rsync -arvz --ignore-existing --progress $out $backup | tee -a $log_f
    rsync -arvz --progress $in "$(dirname $out)" | tee -a $log_f
}

sub i=zsh/.zshrc o=.zshrc
sub i=zsh/.zprofile o=.zprofile
sub i=zsh/.p10k.zsh o=.p10k.zsh
sub i=zsh/config.d o=.config/zsh/config.d
sub i=gh/config.yml o=.config/gh/config.yml
sub i=git/.gitconfig o=.gitconfig
sub i=glab/aliases.yml o=.config/glab-cli/aliases.yml
sub i=glab/config.yml o=.config/glab-cli/config.yml
sub i=htop o=.config
