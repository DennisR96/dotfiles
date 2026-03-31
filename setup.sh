# Hello World

if [[ $(uname) == "Darwin" ]]; then
  echo "Running on macOS"
  brew install fzf
  brew install --cask raycast
else 
  echo "Running on Linux"
  # Install zsh and set it as the default shell
  apt install zsh
  chsh -s $(which zsh)

  apt install fzf
  apt install eza

  apt install neovim
  
fi




