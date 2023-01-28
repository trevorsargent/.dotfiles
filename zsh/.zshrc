if [[ $OSTYPE == 'darwin'* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export NVM_COMPLETION=true

# include go
export PATH=$PATH:~/go/bin

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

# autojump
[ -f $(brew --prefix autojump)/etc/profile.d/autojump.sh ] && . $(brew --prefix autojump)/etc/profile.d/autojump.sh

export NODE_OPTIONS=--max_old_space_size=16382

export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion

export PICO_SDK_PATH=/home/trevor/Code/pico/pico-sdk

export PATH=/Users/trevor/.nimble/bin:$PATH

parse_git_branch() {
  git branch &>/dev/null
  if [ $? -eq 0 ]; then
    echo "%F{008}[%f $(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/') %F{008}]%f"
  fi

}

copy_function() {
  test -n "$(declare -f "$1")" || return
  eval "${_/$1/$2}"
}

rename_function() {
  copy_function "$@" || return
  unset -f "$1"
}

node_version() {
  nvm use &>/dev/null
  if [ $? -eq 0 ]; then
    echo " %F{002}$(node --version)%f"
  fi
}

set_prompt() {
  nvm use >/dev/null 2>/dev/null
  PROMPT="%F{008}[%f %~ %F{008}]%f %(!.#.)"
  RPROMPT=" $(parse_git_branch)$(node_version)"
}

function cd {
  builtin cd "$@"
  set_prompt
}

set_prompt

rename_function j jj

j() {
  jj >/dev/null
}
