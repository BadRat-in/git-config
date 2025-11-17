# Add git hook installer to PATH
hook_installer="$HOME/.config/git/git-hook-install.sh"
if [ -f "$hook_installer" ]; then
  alias git-hook-install="$hook_installer"
  alias ghi="git-hook-install"
else
  alias git-hook-install=true
fi

# Git shortcuts
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
alias gi='git init && git-hook-install'
alias gf='git fetch'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'
alias gm='git merge'
alias gn='git checkout -b'  # new branch
alias gp='git push'
alias gr='git reset'
alias gs='git status --short'
alias gu='git pull'
