# --- Historial ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_ignore_space

# --- Autocompletado nativo ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Ignora mayúsculas/minúsculas

# --- Navegación del historial con teclas Arriba / Abajo ---
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# --- Aliases útiles ---
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias xi='sudo xbps-install -S'
alias xr='sudo xbps-remove -R'
alias xu='sudo xbps-install -Su'
alias xq='xbps-query -Rs'

# --- Plugins ---
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Prompt (Starship debe ir al final) ---
eval "$(starship init zsh)"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
export PATH="$HOME/.zvm/bin:$PATH"
export PATH=$HOME/.local/bin:$PATH
