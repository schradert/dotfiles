### PRE ###

# Powerlevel10k (first because instant prompt)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source ~/.p10k.zsh

### MAIN ###
find "$HOME/.config/zsh/config.d" -maxdepth 1 -type f -exec source {} \;

# PLUGINS
export PATH="$HOME/.local/bin:/usr/local/bin:$HOME/.config/wtf:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
fpath+=($ZSH/custom/plugins/zsh-completions/src)
plugins=(
    aliases
    ansible
    battery
    brew
    colored-man-pages
    command-not-found
    common-aliases
    cp
    dirhistory
    docker
    docker-compose
    fast-syntax-highlighting
    gcloud
    gh
    git
    git-auto-fetch
    git-extra-commands
    golang
    iterm2
    nix-zsh-completions
    pip
    poetry
    python
    ripgrep
    rsync
    terraform
    tmux
    vscode
    zsh-aliases-exa
    zsh-256color
)

# AUTOSUGGESTIONS
ZSH_AUTOSUGGEST_STRATEGY=("history" "completion")
plugins+=(zsh-autosuggestions)

# COMMAND NOT FOUND
source $(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh

# DIRENV
eval "$(direnv hook zsh)"

# (THE)FUCK
eval $(thefuck --alias)

# FZF
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
source ~/.fzf.zsh
source ~/.fzf-gcloud.plugin.zsh
plugins+=(
fzf
fzf-tab
)
bindkey "^R" fzf-history-widget

# KUBERNETES
plugins+=(
helm
kubectl
operator-sdk
)

# YOU SHOULD USE
export YSU_HARDCORE=1
export YSU_MESSAGE_POSITION="after"
export YSU_MODE="ALL"
plugins+=(you-should-use)

# ZOXIDE
eval "$(zoxide init zsh)"

source $ZSH/oh-my-zsh.sh

### POST ###

# NIX
prompt_nix_shell_setup
export PATH=$PATH:/Users/tristanschrader/.spicetify
