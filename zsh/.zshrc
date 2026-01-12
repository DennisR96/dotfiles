eval "$(/opt/homebrew/bin/brew shellenv)"
# Paths
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"
export KEYTIMEOUT=1
export PYTHONDONTWRITEBYTECODE=1

# Alias
alias ls='eza --icons=always --hyperlink -a'
alias nvf='fzf --preview "bat --style=numbers --color=always {} || cat {}" --preview-window=right:60% --bind "enter:become(nvim {})"'
alias nvg='rg --no-heading --line-number --color=always "" | fzf --ansi --delimiter : --preview "bat --style=numbers --color=always {1} --highlight-line {2}" --bind "enter:become(nvim {1} +{2})"'
alias src='source .venv/bin/activate'
alias venv='python3.12 -m venv .venv'

# Alias Docker d 
alias dpsa='docker ps -a' 
alias reload='source ~/.zshrc'

# Computer Title
autoload -U colors && colors
PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~ %{$reset_color%}%% "
bindkey -v

# Starship
eval "$(starship init zsh)"
source <(fzf --zsh)
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
eval "$(zoxide init zsh)"


# Added by Antigravity
export PATH="/Users/dennisrak/.antigravity/antigravity/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/dennisrak/.cache/lm-studio/bin"
# End of LM Studio CLI section

# Clipboard Copy Function
function clipcopy() {
    local target_dir="${1:-.}"
    local file_pattern="$2"
    local find_args=( "$target_dir" )

    if [[ -n "$file_pattern" ]]; then
        find_args+=( -name "$file_pattern" )
    else
        find_args+=( -type f )
    fi

    find "${find_args[@]}" -exec tail -n +1 {} + | pbcopy
    
    echo "Copied contents of files in '${target_dir}' ${file_pattern:+matching '${file_pattern}' }to clipboard."
}

