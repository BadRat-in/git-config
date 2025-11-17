# Local Git Configuration

This repository stores Git configuration files to help set up a consistent development environment across systems. All files are placed under `~/.config/git/`.

**Key Architecture:** This configuration follows a **single source of truth** principle - all Git settings (both personal user info and shared team settings) are stored in `~/.config/git/config`. Your `~/.gitconfig` file contains only a minimal include directive. This approach provides:
- Single location to manage all Git configuration
- Easy backup and synchronization
- Clear separation between user settings and shared settings
- Simplified troubleshooting

**Note:** GPG signing is optional and can be configured during installation. The installer will prompt you and automatically configure everything if desired.

## Structure

```plaintext
.config/git/
├── config                # Main Git config (equivalent to ~/.gitconfig)
├── ignore                # Global .gitignore file
└── commit-template.txt   # Default commit message template
```

## Files

### `config`

This is the **single source of truth** for all Git configuration. After installation, it contains:

1. **User Settings** (at the top):
   ```ini
   [user]
     name = Your Name
     email = you@example.com
     signingkey = YOUR_GPG_KEY  # Optional, only if GPG enabled
   ```

2. **Shared Team Settings** (below):
   ```ini
   [core]
     excludesFile = ~/.config/git/ignore
     editor = nano  # Your chosen editor (nano, vim, nvim, code, etc.)
     autocrlf = input

   [commit]
     template = ~/.config/git/commit-template.txt
     gpgsign = false  # Changed to true if GPG enabled

   [alias]
     # Various helpful aliases

   [gpg]  # Only added if GPG signing enabled
     program = gpg  # Your GPG program path
   ```

The installer automatically merges your personal settings with the shared configuration during setup.

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

### `hooks/commit-msg.sh`

A standalone POSIX shell script that validates commit messages against Conventional Commits format. This hook:

- Requires NO dependencies (no Node.js, npm, or commitlint)
- Works on any POSIX-compliant system (macOS, Linux, BSD)
- Validates commit format: `type(scope)?: subject`
- Enforces lowercase subject, no trailing period
- Enforces minimum subject length of 10 characters
- Validates subject maximum length of 72 characters
- Allows merge commits and reverts to bypass validation
- Validates BREAKING CHANGE formatting
- Provides helpful error messages with examples

```text
# feat:
# fix:
# style:
# ci:
# deploy:

# chore:
# docs:
# refactor:

# perf:
# test:
# debug:
# BREAKING CHANGE:
```

## Installation

### Quick Install (Recommended)

Run the automated installer script:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh)"
```

Or with wget:

```sh
sh -c "$(wget -qO- https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh)"
```

**Interactive Installation:**
The script will prompt you for:
- Your name and email
- Preferred editor (default: nano)
- GPG configuration (optional):
  - Enable GPG signing?
  - GPG key ID
  - GPG program path (default: gpg)

And automatically:
- Backup existing files (auto-cleaned on success)
- Create `~/.config/git/` directory
- Download all configuration files
- Write your user information to `~/.config/git/config`
- Configure editor preference
- Create minimal `~/.gitconfig` with include directive
- Configure GPG signing if requested (including gpg.program)

**Non-Interactive Installation:**

```sh
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --yes \
  --name "Your Name" \
  --email "your.email@example.com"
```

**Update Existing Installation:**

```sh
# Update only the commit-msg hook and git shortcuts (preserves other config)
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --update
```

**With Commit Message Validation (Recommended for Teams):**

```sh
# Option 1: Quick install hook in current repository only
cd /path/to/your/repo
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --apply-here

# Option 2: Set up global hooks template for all new repositories
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --global-hooks

# Note: Global hooks (--global-hooks) only apply to NEW repos created after setup.
# For existing repos, use --apply-here or manually copy the hook.
```

**With Shell Integration (Recommended):**

```sh
# Install with shell config integration (adds git shortcuts and hook installer alias)
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --setup-shell

# This will:
# - Add git shortcuts (ga, gc, gp, etc.) to your shell config
# - Add 'git-hook-install' alias for easy hook installation
# - Auto-detect your shell (zsh, bash, fish, etc.)
```

**With Husky/Commitlint (For Node.js Projects):**

```sh
# Install hooks in specific Node.js repositories
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --install-husky \
  --repos "/path/to/repo1,/path/to/repo2"

# Set up global hooks template with Node.js-based validation
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh | sh -s -- \
  --install-husky \
  --global-hooks
```

**Help and Options:**

```sh
# Download and view all options
curl -fsSL https://raw.githubusercontent.com/BadRat-in/git-config/main/install.sh -o install.sh
chmod +x install.sh
./install.sh --help
```

### Manual Installation

If you prefer to install manually:

1. Clone or copy the files into your config directory:

   ```sh
   mkdir -p ~/.config/git
   cp -r path/to/this/repo/* ~/.config/git/
   ```

2. Update the `config` file with your user information at the top:

   ```sh
   # Edit ~/.config/git/config and add at the very top:
   cat > ~/.config/git/config.tmp << 'EOF'
   [user]
       name = Your Name
       email = your.email@example.com
       # signingkey = YOUR_GPG_KEY  # Optional

   # ============================================================================
   # Shared Configuration
   # ============================================================================

   EOF
   cat ~/.config/git/config >> ~/.config/git/config.tmp
   mv ~/.config/git/config.tmp ~/.config/git/config
   ```

3. Create minimal `~/.gitconfig` with include directive:

   ```sh
   cat > ~/.gitconfig << 'EOF'
   # Git Configuration
   # All settings are managed in ~/.config/git/config

   [include]
       path = ~/.config/git/config
   EOF
   ```

4. Verify the settings:

   ```sh
   git config --list --show-origin
   ```

5. (Optional) Set up commit message validation hook:

   **Quick method (recommended):**
   ```sh
   # Navigate to your repository and run the installer with --apply-here
   cd /path/to/your/repo
   ~/.config/git/install.sh --apply-here
   ```

   **Manual method:**
   ```sh
   # Create hooks directory in your repository
   mkdir -p .git/hooks

   # Copy the standalone hook
   cp ~/.config/git/hooks/commit-msg.sh .git/hooks/commit-msg

   # Make it executable (required)
   chmod +x .git/hooks/commit-msg

   # Or with numeric permissions
   chmod 755 .git/hooks/commit-msg
   ```

   **Quick command (if you have shell integration):**
   ```sh
   # Navigate to your repository
   cd /path/to/your/repo

   # Run the installer alias (requires --setup-shell from main installation)
   git-hook-install
   ```

   **Global template for all new repositories:**

   ```sh
   # Create template directory
   mkdir -p ~/.config/git/templates/hooks

   # Copy the hook
   cp ~/.config/git/hooks/commit-msg.sh ~/.config/git/templates/hooks/commit-msg
   chmod +x ~/.config/git/templates/hooks/commit-msg

   # Configure git to use the template
   git config --global init.templateDir ~/.config/git/templates

   # Apply to existing repo (run in repo directory)
   git init
   ```

## Git Shortcuts

If you installed with `--setup-shell`, the following git shortcuts are available in your shell:

```sh
ga='git add'              # Stage files
gap='git add --patch'     # Stage files interactively
gb='git branch'           # List branches
gba='git branch --all'    # List all branches (including remote)
gc='git commit'           # Commit changes
gca='git commit --amend --no-edit'  # Amend last commit without editing message
gce='git commit --amend'  # Amend last commit and edit message
gco='git checkout'        # Switch branches
gcl='git clone --recursive'  # Clone with submodules
gd='git diff'             # Show changes
gds='git diff --staged'   # Show staged changes
gi='git init'             # Initialize repository
gl='git log --graph --all --pretty=format:...'  # Pretty log
gm='git merge'            # Merge branches
gn='git checkout -b'      # Create new branch
gp='git push'             # Push changes
gr='git reset'            # Reset changes
gs='git status --short'   # Short status
gu='git pull'             # Pull changes
```

These shortcuts are defined in `~/.config/git/git_shortcut.zsh` (or `.bash`, `.sh` depending on your shell) and are automatically sourced from your shell config file.

## Quick Hook Installation Tool

After installing with `--setup-shell`, you can use the `git-hook-install` command to quickly install commit message validation hooks in any repository:

```sh
# Navigate to any git repository
cd /path/to/your/repo

# Install the hook
git-hook-install
```

This is equivalent to manually copying and making the hook executable, but much faster and easier to remember!

## GPG Signing Configuration

GPG signing is **automatically configured during installation** if you choose to enable it. The installer will:
- Detect and list your available GPG keys
- Prompt you to enter your key ID
- Prompt you to enter GPG program path (default: gpg)
- Write the key to `[user]` section in `~/.config/git/config`
- Add `[gpg]` section with program configuration
- Automatically enable signing for commits and tags

**If you didn't enable GPG during installation and want to enable it now:**

1. Generate a GPG key (if you don't have one):

   ```sh
   gpg --full-generate-key
   ```

2. List your GPG keys and copy the key ID:

   ```sh
   gpg --list-secret-keys --keyid-format=long
   ```

3. Edit `~/.config/git/config` (single source of truth):

   ```sh
   # Add to the [user] section at the top:
   [user]
       name = Your Name
       email = your.email@example.com
       signingkey = YOUR_KEY_ID

   # Change these settings from false to true:
   [commit]
       gpgsign = true

   [tag]
       gpgSign = true

   # Add at the end of the file:
   [gpg]
       program = gpg  # Or gpg2, /usr/local/bin/gpg, etc.
   ```

4. Add your GPG key to GitHub/GitLab (copy public key):

   ```sh
   gpg --armor --export YOUR_KEY_ID
   ```

**Note:** All configuration is done in `~/.config/git/config` - this is the single source of truth. You don't need to modify `~/.gitconfig`.

## License

This setup is provided for personal use. Feel free to adapt it to your own workflows.
