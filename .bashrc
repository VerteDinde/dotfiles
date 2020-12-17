# Paths
PATH=$PATH:~/bin
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GOPATH="$HOME/go"
export PATH="$PATH:$HOME/flutter/bin"
export PATH="$PATH:$HOME/Documents/electron-core/depot_tools"
export PATH="$PATH:$HOME/Documents/electron-core/electron-gn-scripts/nix:"

#  Git Command Prompt Settings
source ~/.git-prompt.sh
source ~/.git-completion.sh

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWCOLORHINTS=true

export PS1='🦄 🔹\[\e[0;36m\]\[\e[0;36m\] \W\[\033[0;35m\]$(__git_ps1 " (%s)")\[\e[0m\]: '

git config --global core.editor "/usr/bin/vim"

# Aliases
alias evernote=open firefox -new-tab -url https://www.evernote.com/Home.action
