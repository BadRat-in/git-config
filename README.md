# Local Git Configuration

This repository stores personal Git configuration files to help set up a consistent development environment across systems. All files are intended to be placed under `~/.config/git/`.

**Note:** This repo contains configuration for _my preferences_, If you can copy them but it might require you to change configuration for your system.

## Structure

```plaintext
.config/git/
├── config                # Main Git config (equivalent to ~/.gitconfig)
├── ignore                # Global .gitignore file
└── commit-template.txt   # Default commit message template
````

## Files

### `config` (formerly `~/.gitconfig`)

This file contains your personal Git configuration, including user info, aliases, diff settings, and references to the ignore file and commit template. Example contents:

```ini
[user]
  name = Your Name
  email = you@example.com

[core]
  excludesFile = ~/.config/git/ignore
  editor = nvim
  autocrlf = input

[commit]
  template = ~/.config/git/commit-template.txt

[alias]
  co = checkout
  br = branch
  ci = commit
  st = status
```

### `ignore`

Global `.gitignore` file that applies to all your repositories. Customize as needed. Example contents:

```gitignore
# macOS
.DS_Store

# Node
node_modules/

# Logs
*.log

# Editor/IDE
.vscode/
*.swp
.idea/
```

### `commit-template.txt`

A template used for commit messages to encourage clear, consistent messages.

```text
# feat: 
# feat: 
# feat: 
# feat: 

# fix: 
# fix: 
# fix: 
# fix: 

# style: 
# style: 
# style: 

# ci: 
# ci: 

# deploy: 
# deploy: 

# chore: 
# chore: 
# chore: 
# docs: 

# refactor: 
# perf: 

# test: 
# debug: 

# BREAKING CHANGE: 
# BREAKING CHANGE: 
# BREAKING CHANGE: 
```

## Installation

To use this configuration:

1. Clone or copy the files into your config directory:

   ```sh
   mkdir -p ~/.config/git
   cp -r path/to/this/repo/* ~/.config/git/
   ```

2. Copy the config file into the ~/.gitconfig file:

   ```sh
   cp ~/.config/git/config ~/.gitconfig
   ```

3. (Optional) Verify the settings:

   ```sh
   git config --list --show-origin
   ```

## License

This setup is provided for personal use. Feel free to adapt it to your own workflows.
