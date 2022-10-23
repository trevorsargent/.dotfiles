eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
source ~/.powerlevel10k/powerlevel10k.zsh-theme

export NVM_COMPLETION=true

# include go
export PATH=$PATH:~/go/bin

# List out all globally installed npm packages
alias list-npm-globals='npm list -g --depth=0'

# DIRCOLORS (MacOS)
export CLICOLOR=1

# FZF
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --margin=1 --padding=1"

# PATH
# export PATH=${PATH}:/usr/local/go/bin
# export PATH=${PATH}:${HOME}/go/bin
export PATH=${PATH}:/snap/bin

export BAT_THEME="gruvbox-dark"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# autojump
[ -f $(brew --prefix autojump)/etc/profile.d/autojump.sh ] && . $(brew --prefix autojump)/etc/profile.d/autojump.sh

export NODE_OPTIONS=--max_old_space_size=16382

  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"  # This loads nvm
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export PICO_SDK_PATH=/home/trevor/Code/pico/pico-sdk
