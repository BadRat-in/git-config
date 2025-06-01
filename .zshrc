# -------------------------- Home Brew --------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

# Display system info on terminal startup
neofetch

# ------------------------- Start Aliases --------------------------
# Alias for listing Xcode simulator devices
alias list-device="xcrun simctl list 'devices'"

# Alias for Flutter version FlutterFlow
alias flutterflow="$HOME/Library/Application\ Support/io.flutterflow.prod.mac/flutter/bin/flutter"

# Git aliases for convenience
# Aliases: git
alias ga='git add'
alias gap='ga --patch'
alias gb='git branch'
alias gba='gb --all'
alias gc='git commit'
alias gca='gc --amend --no-edit'
alias gce='gc --amend'
alias gco='git checkout'
alias gcl='git clone --recursive'
alias gd='git diff --output-indicator-new=" " --output-indicator-old=" "'
alias gds='gd --staged'
alias gi='git init'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'
alias gm='git merge'
alias gn='git checkout -b'  # new branch
alias gp='git push'
alias gr='git reset'
alias gs='git status --short'
alias gu='git pull'

# Ngrok aliase with predefined url
alias ngurl='ngrok http --url=workable-externally-possum.ngrok-free.app'

# ------------------------- End Aliases --------------------------

# ------------------------- Start PATHs --------------------------
# Add custom paths to PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$PATH:/Applications/google-cloud-sdk/bin"
export PATH="$PATH:/Applications/flutter/bin"
export OPENSSL_INCLUDES="/opt/homebrew/opt/openssl@3/include"
export OPENSSL_LIB="/opt/homebrew/opt/openssl@3/lib"

# Add NVM Path to PATH and setup NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Add path for the Java HOME
export JAVA_HOME="/Applications/jdk-23.0.1.jdk/Contents/Home"

# FlutterFire CLI
export PATH="$PATH:$HOME/.pub-cache/bin"

# Add go blueprint to PATH
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# ------------------------- End PATHs --------------------------

# ------------------------- Start ZSH Super Charge  --------------------------
# Configuring Zsh plugins to supercharge the macOS Terminal app
# Add zsh-completions to the fpath
fpath=($HOME/.zsh/zsh-completions/src /opt/homebrew/share/zsh/site-functions /usr/local/share/zsh/site-functions /usr/share/zsh/site-functions /usr/share/zsh/5.9/functions)

# Initialize completion system
autoload -Uz compinit && compinit

# Enable zsh-syntax-highlighting for command syntax highlighting
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Enable zsh-modern-theme for a modern Zsh theme with Git status and command duration
source $HOME/.zsh/zsh-modern-theme/modern-theme.zsh

# Enable zsh-autosuggestions for command history suggestions
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Enable zsh-history-substring-search for searching command history
source $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

# Enable zsh-you-should-use to remind you to use Zsh features
source $HOME/.zsh/zsh-you-should-use/you-should-use.zsh

# Enable zsh-interactive-cd for an enhanced 'cd' command experience
source $HOME/.zsh/zsh-interactive-cd/zsh-interactive-cd.zsh

# ------------------------- End ZSH Super Charge  --------------------------
