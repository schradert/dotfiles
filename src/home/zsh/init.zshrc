bindkey '^R' fzf-history-widget
prompt_nix_shell_setup
export GEM_HOME="$HOME/.gem"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$GEM_HOME/ruby/3.2.0/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
# TODO: only include lines if the tools are being used!
export PATH="$HOME/.spicetify:$PATH"
export PATH="$PATH:$HOME/.config/wtf"
export XDG_CONFIG_HOME="$HOME/.config"
fpath+=($ZSH/custom/plugins/zsh-completions/src)
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors $LS_COLORS  # ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
