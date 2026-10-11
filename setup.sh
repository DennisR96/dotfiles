#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

install_brew() {
  brew install "$@"
}

install_brew_cask() {
  brew install --cask "$@"
}

install_apt() {
  sudo apt-get install -y "$@"
}

install_zsh_vi_mode_manual() {
  local target="$HOME/.zsh/zsh-vi-mode"

  if [[ -d "$target/.git" ]]; then
    git -C "$target" pull --ff-only
  else
    mkdir -p "$(dirname "$target")"
    git clone https://github.com/jeffreytse/zsh-vi-mode.git "$target"
  fi
}

install_neovim_linux() {
  local arch asset tmpdir

  case "$(uname -m)" in
    x86_64|amd64) asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *)
      echo "Unsupported architecture for Neovim binary: $(uname -m)" >&2
      echo "Install Neovim >= 0.9 manually from https://github.com/neovim/neovim/releases" >&2
      return 1
      ;;
  esac

  tmpdir="$(mktemp -d)"
  curl -L "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmpdir/$asset"
  tar -xzf "$tmpdir/$asset" -C "$tmpdir"
  sudo rm -rf /opt/nvim
  sudo mv "$tmpdir"/nvim-linux-* /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmpdir"
}

install_eza_linux() {
  if apt-cache show eza >/dev/null 2>&1; then
    install_apt eza
    return
  fi

  echo "eza not found in the default apt repositories; adding the official eza repository"
  install_apt ca-certificates gnupg wget

  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

  sudo apt-get update
  install_apt eza
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    mv "$target" "$target.$BACKUP_SUFFIX"
    echo "Backed up $target to $target.$BACKUP_SUFFIX"
  fi

  ln -s "$source" "$target"
  echo "Linked $target -> $source"
}

if [[ "$(uname)" == "Darwin" ]]; then
  echo "Running on macOS"
  install_brew fzf eza neovim zsh ripgrep zsh-vi-mode
  install_brew_cask raycast wezterm
else
  echo "Running on Linux"
  sudo apt-get update
  install_apt zsh fzf ripgrep git curl ca-certificates
  install_neovim_linux
  install_eza_linux
  install_zsh_vi_mode_manual

  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    chsh -s "$(command -v zsh)"
  fi
fi

link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/pi" "$HOME/.pi"
link_file "$DOTFILES_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"

echo "Setup complete."
