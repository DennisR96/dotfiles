# -- Alias --
alias reload='source ~/.zshrc'
alias cap="PYTHONPATH=/Users/dennisrak/Developer python3 -m cap"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# Docker
alias d="docker"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"

# Network
alias ports="netstat -tulanp"
alias myip="curl http://ipecho.net/plain; echo"
alias cf="tail -n +1 * | pbcopy && echo 'Copied Folder to clipboard!'"

# -- Paths -- 
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
export PATH="$HOME/dotfiles/bin:$PATH"


# -- Python --
export KEYTIMEOUT=1
export PYTHONDONTWRITEBYTECODE=1
eval "$(/opt/homebrew/bin/brew shellenv)"

# Paths

# Alias
alias ls='eza --icons=always'
alias tree='eza --tree | pbcopy' 
alias nvf='fzf --preview "bat --style=numbers --color=always {} || cat {}" --preview-window=right:60% --bind "enter:become(nvim {})"'
alias nvg='rg --no-heading --line-number --color=always "" | fzf --ansi --delimiter : --preview "bat --style=numbers --color=always {1} --highlight-line {2}" --bind "enter:become(nvim {1} +{2})"'
alias src='source .venv/bin/activate'
alias venv='python3.12 -m venv .venv'


# Computer Title
autoload -U colors && colors
PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~ %{$reset_color%}%% "
bindkey -v

# Starship
eval "$(starship init zsh)"
source <(fzf --zsh)
if command -v brew >/dev/null 2>&1 && [[ -f "$(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]]; then
  source "$(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
elif [[ -f "$HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]]; then
  source "$HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
eval "$(zoxide init zsh)"


# Created by `pipx` on 2026-05-08 09:07:54
export PATH="$PATH:/Users/dennisrak/.local/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/dennisrak/.cache/lm-studio/bin"
# End of LM Studio CLI section

[[ -f /Users/dennisrak/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /Users/dennisrak/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh

# Pi
export PATH="/opt/homebrew/Cellar/node/26.0.0/bin:$PATH"
