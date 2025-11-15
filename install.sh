#!/usr/bin/env sh
# Git Config Installer with optional Husky/Commitlint bootstrap
# Repository: https://github.com/BadRat-in/git-config
#
# This script configures global Git settings and optionally bootstraps
# commit hooks (Husky + Commitlint + lint-staged) for local repositories.

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_URL="https://raw.githubusercontent.com/BadRat-in/git-config/main"
CONFIG_DIR="$HOME/.config/git"
GITCONFIG="$HOME/.gitconfig"
TEMPLATE_DIR_DEFAULT="$HOME/.config/git/templates"

# Files to download from repository
# Format: "remote_name:local_name"
FILES="
commit-template-txt:commit-template-txt
config:config
ignore:ignore
"

# Optional files (won't fail if missing)
OPTIONAL_FILES="
commitlint.config.js:commitlint.config.js
package.json:package.json
hooks/commit-msg.sh:hooks/commit-msg.sh
git-hook-install.sh:git-hook-install.sh
git_shortcut.zsh:git_shortcut.zsh
git_shortcut.bash:git_shortcut.bash
git_shortcut.sh:git_shortcut.sh
"

# ============================================================================
# COLORS AND OUTPUT
# ============================================================================

# Check if terminal supports colors
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

info() {
    printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$1"
}

success() {
    printf "%s[SUCCESS]%s %s\n" "$GREEN" "$RESET" "$1"
}

warn() {
    printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$1" >&2
}

error() {
    printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$1" >&2
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

AUTO_YES=0
USER_NAME=""
USER_EMAIL=""
INSTALL_HUSKY=0
GLOBAL_HOOKS=0
APPLY_HERE=0
REPOS=""
TEMPLATE_DIR="$TEMPLATE_DIR_DEFAULT"
SETUP_SHELL_INTEGRATION=0

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Configure global Git settings and optionally bootstrap commit hooks.

OPTIONS:
    -y, --yes               Accept all prompts (non-interactive mode)
    --name NAME             Set git user.name
    --email EMAIL           Set git user.email
    --install-husky         Install Husky + Commitlint + lint-staged in repos
    --global-hooks          Set up global git template directory for hooks
    --apply-here            Install commit-msg hook in current repository
    --repos PATHS           Comma-separated paths to repos (use with --install-husky)
    --template-dir PATH     Override template directory (default: $TEMPLATE_DIR_DEFAULT)
    --setup-shell           Add git shortcuts and hook installer to shell config
    -h, --help              Show this help message

EXAMPLES:
    # Interactive installation
    $0

    # Non-interactive with user info
    $0 --yes --name "John Doe" --email "john@example.com"

    # Set up global hooks template (for all new repositories)
    $0 --global-hooks

    # Install hook in current repository only
    $0 --apply-here

    # Install with Husky in specific repos
    $0 --install-husky --repos "/path/to/repo1,/path/to/repo2"

EXIT CODES:
    0    Success
    1    General error
    2    Missing downloader (curl/wget)
    3    Missing Node/npm (when --install-husky requires it)

EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=1
            shift
            ;;
        --name)
            USER_NAME="$2"
            shift 2
            ;;
        --email)
            USER_EMAIL="$2"
            shift 2
            ;;
        --install-husky)
            INSTALL_HUSKY=1
            shift
            ;;
        --global-hooks)
            GLOBAL_HOOKS=1
            shift
            ;;
        --apply-here)
            APPLY_HERE=1
            shift
            ;;
        --repos)
            REPOS="$2"
            shift 2
            ;;
        --template-dir)
            TEMPLATE_DIR="$2"
            shift 2
            ;;
        --setup-shell)
            SETUP_SHELL_INTEGRATION=1
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_downloader() {
    if command -v curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
        DOWNLOAD_CMD="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
        DOWNLOAD_CMD="wget -qO-"
    else
        error "Neither curl nor wget found. Please install one of them."
        exit 2
    fi
    info "Using $DOWNLOADER for downloads"
}

check_node_npm() {
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js not found but required for --install-husky"
        error "Please install Node.js from https://nodejs.org/"
        exit 3
    fi

    if ! command -v npm >/dev/null 2>&1; then
        error "npm not found but required for --install-husky"
        error "Please install npm (usually comes with Node.js)"
        exit 3
    fi

    info "Node $(node --version) and npm $(npm --version) detected"
}

# ============================================================================
# USER INPUT
# ============================================================================

prompt_yes_no() {
    prompt="$1"
    default="${2:-n}"

    if [ "$AUTO_YES" = "1" ]; then
        return 0
    fi

    if [ "$default" = "y" ]; then
        prompt_text="$prompt [Y/n]: "
    else
        prompt_text="$prompt [y/N]: "
    fi

    printf "%s" "$prompt_text"
    read -r response

    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Nn]|[Nn][Oo])
            return 1
            ;;
        "")
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            warn "Invalid response. Please answer yes or no."
            prompt_yes_no "$1" "$2"
            ;;
    esac
}

prompt_input() {
    prompt="$1"
    current_value="$2"

    # In non-interactive mode, use current value or return empty
    if [ "$AUTO_YES" = "1" ]; then
        if [ -n "$current_value" ]; then
            printf "%s\n" "$current_value"
        else
            printf "\n"
        fi
        return
    fi

    # Output prompt to stderr so it's visible when using command substitution
    if [ -n "$current_value" ]; then
        printf "%s [%s]: " "$prompt" "$current_value" >&2
    else
        printf "%s: " "$prompt" >&2
    fi

    read -r input

    # If user just pressed Enter and there's a current value, use it
    if [ -z "$input" ] && [ -n "$current_value" ]; then
        printf "%s\n" "$current_value"
    else
        printf "%s\n" "$input"
    fi
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

download_file() {
    remote_path="$1"
    local_path="$2"
    is_optional="${3:-0}"

    url="$REPO_URL/$remote_path"

    # Create parent directory if needed
    local_dir="$(dirname "$local_path")"
    if [ ! -d "$local_dir" ]; then
        mkdir -p "$local_dir"
    fi

    info "Downloading $remote_path..."

    if [ "$DOWNLOADER" = "curl" ]; then
        if curl -fsSL "$url" -o "$local_path" 2>/dev/null; then
            # Make executable if it's a shell script
            case "$local_path" in
                *.sh)
                    chmod +x "$local_path"
                    ;;
            esac
            success "Downloaded to $local_path"
            return 0
        fi
    else
        if wget -qO "$local_path" "$url" 2>/dev/null; then
            # Make executable if it's a shell script
            case "$local_path" in
                *.sh)
                    chmod +x "$local_path"
                    ;;
            esac
            success "Downloaded to $local_path"
            return 0
        fi
    fi

    if [ "$is_optional" = "1" ]; then
        warn "Optional file $remote_path not found, skipping"
        return 0
    else
        error "Failed to download $remote_path"
        return 1
    fi
}

backup_file() {
    file="$1"

    if [ ! -f "$file" ]; then
        return 0
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)
    backup="${file}.bak.${timestamp}"

    info "Backing up $file to $backup"
    cp "$file" "$backup"
    success "Backup created at $backup"
}

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

install_config_files() {
    info "Creating configuration directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"

    # Download required files
    echo "$FILES" | while IFS=: read -r remote local; do
        # Skip empty lines
        [ -z "$remote" ] && continue

        download_file "$remote" "$CONFIG_DIR/$local" 0 || exit 1
    done

    # Download optional files
    echo "$OPTIONAL_FILES" | while IFS=: read -r remote local; do
        # Skip empty lines
        [ -z "$remote" ] && continue

        download_file "$remote" "$CONFIG_DIR/$local" 1
    done

    success "Configuration files downloaded to $CONFIG_DIR"
}

configure_gitconfig() {
    info "Configuring Git user settings..."

    # Get current git config values if not provided
    if [ -z "$USER_NAME" ]; then
        current_name=$(git config --global user.name 2>/dev/null || echo "")
        USER_NAME=$(prompt_input "Enter your Git user name" "$current_name")
    fi

    if [ -z "$USER_EMAIL" ]; then
        current_email=$(git config --global user.email 2>/dev/null || echo "")
        USER_EMAIL=$(prompt_input "Enter your Git email" "$current_email")
    fi

    # Validate that we have user name and email
    if [ -z "$USER_NAME" ] || [ -z "$USER_EMAIL" ]; then
        error "User name and email are required"
        error "Provide them via --name and --email flags, or run without --yes for interactive mode"
        exit 1
    fi

    # Backup existing .gitconfig
    backup_file "$GITCONFIG"

    # Create new .gitconfig
    info "Creating new $GITCONFIG"

    cat > "$GITCONFIG" << EOF
# Git Configuration
# Generated by git-config installer on $(date)
# Repository: https://github.com/BadRat-in/git-config

[user]
	name = $USER_NAME
	email = $USER_EMAIL

# Include shared configuration from ~/.config/git/config
[include]
	path = $CONFIG_DIR/config

EOF

    success "Created $GITCONFIG with user settings and include directive"
    success "User: $USER_NAME <$USER_EMAIL>"
}

# ============================================================================
# HUSKY / COMMITLINT / LINT-STAGED INSTALLATION
# ============================================================================

is_git_repo() {
    repo_path="$1"
    [ -d "$repo_path/.git" ] || [ -f "$repo_path/.git" ]
}

install_hooks_in_repo() {
    repo_path="$1"

    info "Processing repository: $repo_path"

    if ! is_git_repo "$repo_path"; then
        warn "$repo_path is not a Git repository, skipping"
        return 1
    fi

    cd "$repo_path" || return 1

    # Check for package.json
    if [ ! -f "package.json" ]; then
        warn "No package.json found in $repo_path"
        if prompt_yes_no "Initialize with npm init -y?" "n"; then
            npm init -y
        else
            warn "Skipping $repo_path"
            return 1
        fi
    fi

    # Install dev dependencies
    info "Installing Husky, Commitlint, and lint-staged..."

    if prompt_yes_no "Install hook dependencies in $repo_path?" "y"; then
        npm install --save-dev \
            husky \
            @commitlint/config-conventional \
            @commitlint/cli \
            lint-staged

        success "Dependencies installed"
    else
        warn "Skipping dependency installation"
        return 1
    fi

    # Setup commitlint config
    if [ ! -f "commitlint.config.js" ]; then
        info "Creating commitlint.config.js"

        if [ -f "$CONFIG_DIR/commitlint.config.js" ]; then
            cp "$CONFIG_DIR/commitlint.config.js" "commitlint.config.js"
        else
            cat > commitlint.config.js << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'chore',
        'ci',
        'deploy',
        'debug'
      ]
    ]
  }
};
EOF
        fi

        success "Created commitlint.config.js"
    fi

    # Initialize Husky
    info "Initializing Husky..."
    npx husky install

    # Add prepare script
    npm pkg set scripts.prepare="husky install"

    # Create commit-msg hook
    info "Creating commit-msg hook..."
    npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'
    chmod +x .husky/commit-msg

    # Create pre-commit hook for lint-staged
    info "Creating pre-commit hook..."
    npx husky add .husky/pre-commit 'npx lint-staged'
    chmod +x .husky/pre-commit

    # Add basic lint-staged config if not present
    if ! grep -q "lint-staged" package.json 2>/dev/null; then
        info "Adding lint-staged configuration to package.json"
        npm pkg set 'lint-staged.*'='eslint --fix'
    fi

    success "Hooks configured in $repo_path"
}

setup_global_hooks() {
    info "Setting up global git template directory: $TEMPLATE_DIR"

    mkdir -p "$TEMPLATE_DIR/hooks"

    # Use the standalone POSIX commit-msg hook if available
    if [ -f "$CONFIG_DIR/hooks/commit-msg.sh" ]; then
        info "Installing standalone commit-msg hook (no Node.js required)"
        cp "$CONFIG_DIR/hooks/commit-msg.sh" "$TEMPLATE_DIR/hooks/commit-msg"
        chmod +x "$TEMPLATE_DIR/hooks/commit-msg"
    else
        # Fallback to Node.js-based hook if standalone not available
        warn "Standalone hook not found, creating Node.js-based hook"
        cat > "$TEMPLATE_DIR/hooks/commit-msg" << 'EOF'
#!/usr/bin/env sh
# Commitlint hook for validating commit messages
# This hook is installed globally via git template directory

if command -v npx >/dev/null 2>&1; then
    npx --no-install commitlint --edit "$1"
else
    echo "Warning: npx not found, skipping commitlint check"
fi
EOF
        chmod +x "$TEMPLATE_DIR/hooks/commit-msg"
    fi

    # Configure git to use template directory
    git config --global init.templateDir "$TEMPLATE_DIR"

    success "Global hooks template configured"
    info "New repositories will automatically include commit-msg hook"
    info "To apply to existing repos, run: git init in each repo"
}

install_standalone_hook() {
    repo_path="${1:-.}"

    info "Installing standalone commit-msg hook in: $repo_path"

    # Check if it's a git repository
    if [ ! -d "$repo_path/.git" ]; then
        error "$repo_path is not a Git repository"
        error "Initialize it first with: git init"
        return 1
    fi

    # Check if hook file exists in config directory
    if [ ! -f "$CONFIG_DIR/hooks/commit-msg.sh" ]; then
        error "Hook file not found: $CONFIG_DIR/hooks/commit-msg.sh"
        error "Please run the main installation first"
        return 1
    fi

    # Create hooks directory if it doesn't exist
    mkdir -p "$repo_path/.git/hooks"

    # Copy the hook
    info "Copying commit-msg hook..."
    cp "$CONFIG_DIR/hooks/commit-msg.sh" "$repo_path/.git/hooks/commit-msg"
    chmod +x "$repo_path/.git/hooks/commit-msg"

    success "Standalone hook installed in $repo_path/.git/hooks/commit-msg"
    info "The hook will now validate all commit messages in this repository"
    info ""
    info "Test it with: echo 'test: invalid' | git commit -F -"
    info "Or try a valid commit: git commit -m 'feat: add new feature here'"
}

install_husky_workflow() {
    check_node_npm

    if [ "$GLOBAL_HOOKS" = "1" ]; then
        setup_global_hooks
    fi

    if [ -n "$REPOS" ]; then
        # Process comma-separated list of repos
        info "Installing hooks in specified repositories..."

        # Use a temporary IFS to split on commas
        old_ifs="$IFS"
        IFS=","
        for repo in $REPOS; do
            IFS="$old_ifs"
            # Trim whitespace
            repo=$(echo "$repo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            if [ -n "$repo" ]; then
                install_hooks_in_repo "$repo"
            fi
        done
        IFS="$old_ifs"
    else
        # Ask if user wants to install in current directory
        if prompt_yes_no "Install hooks in current directory?" "n"; then
            install_hooks_in_repo "$(pwd)"
        fi
    fi
}

# ============================================================================
# SHELL INTEGRATION
# ============================================================================

detect_shell() {
    # Try to detect current shell
    if [ -n "$SHELL" ]; then
        basename "$SHELL"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "sh"
    fi
}

get_shell_config_file() {
    shell_name="$1"
    case "$shell_name" in
        zsh)
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"  # Will be created
            fi
            ;;
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"  # Will be created
            fi
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

setup_shell_integration() {
    shell_name=$(detect_shell)
    config_file=$(get_shell_config_file "$shell_name")

    info "Detected shell: $shell_name"
    info "Shell config file: $config_file"

    # Determine the correct git shortcuts file extension
    case "$shell_name" in
        zsh)
            shortcuts_ext="zsh"
            ;;
        bash)
            shortcuts_ext="bash"
            ;;
        fish)
            shortcuts_ext="fish"
            ;;
        *)
            shortcuts_ext="sh"
            ;;
    esac

    # Add git hook installer to PATH
    hook_installer="$CONFIG_DIR/git-hook-install.sh"
    if [ -f "$hook_installer" ]; then
        if ! grep -q "git-hook-install" "$config_file" 2>/dev/null; then
            info "Adding git hook installer alias to shell config..."
            cat >> "$config_file" << EOF

# Git hook installer (added by git-config installer)
alias git-hook-install="$hook_installer"
alias ghi="git-hook-install"
EOF
            success "Hook installer alias added to $config_file"
        else
            info "Hook installer already configured in shell config"
        fi
    fi

    shortcuts_file="$CONFIG_DIR/git_shortcut.$shortcuts_ext"

    # Check if git shortcuts file exists, otherwise look for generic one
    if [ ! -f "$shortcuts_file" ]; then
        # Try .sh version as fallback
        if [ -f "$CONFIG_DIR/git_shortcut.sh" ]; then
            shortcuts_file="$CONFIG_DIR/git_shortcut.sh"
        elif [ -f "$CONFIG_DIR/git_shortcut.zsh" ]; then
            shortcuts_file="$CONFIG_DIR/git_shortcut.zsh"
        else
            warn "Git shortcuts file not found, skipping shortcuts integration"
            shortcuts_file=""
        fi
    fi

    # Backup shell config
    if [ -f "$config_file" ]; then
        backup="${config_file}.bak.$(date +%Y%m%d_%H%M%S)"
        info "Backing up shell config to: $backup"
        cp "$config_file" "$backup"
    else
        info "Creating new shell config file: $config_file"
        mkdir -p "$(dirname "$config_file")"
        touch "$config_file"
    fi

    # Add git shortcuts
    if [ -n "$shortcuts_file" ] && [ -f "$shortcuts_file" ]; then
        if ! grep -q "source.*git_shortcut" "$config_file" 2>/dev/null; then
            info "Adding git shortcuts to shell config..."
            cat >> "$config_file" << EOF

# Git shortcuts (added by git-config installer)
if [ -f "$shortcuts_file" ]; then
    source "$shortcuts_file"
fi
EOF
            success "Git shortcuts added to $config_file"
        else
            info "Git shortcuts already configured in shell config"
        fi
    fi

    echo ""
    success "Shell integration complete!"
    info "To apply changes, run: source $config_file"
    info "Or restart your terminal"
}

# ============================================================================
# SUMMARY AND CLEANUP
# ============================================================================

show_summary() {
    echo ""
    echo "${BOLD}${GREEN}============================================${RESET}"
    echo "${BOLD}${GREEN}Installation Complete!${RESET}"
    echo "${BOLD}${GREEN}============================================${RESET}"
    echo ""

    echo "${BOLD}Created/Modified Files:${RESET}"
    echo "  - $CONFIG_DIR/config"
    echo "  - $CONFIG_DIR/ignore"
    echo "  - $CONFIG_DIR/commit-template.txt"
    echo "  - $GITCONFIG"

    # Check if any backup files exist
    if ls "${GITCONFIG}.bak."* >/dev/null 2>&1; then
        echo ""
        echo "${BOLD}Backups:${RESET}"
        ls -1 "${GITCONFIG}.bak."* 2>/dev/null | while read -r backup; do
            echo "  - $backup"
        done
    fi

    echo ""
    echo "${BOLD}Git User Configuration:${RESET}"
    echo "  Name:  $USER_NAME"
    echo "  Email: $USER_EMAIL"

    echo ""
    echo "${BOLD}Verify Installation:${RESET}"
    echo "  git config --list --show-origin"

    echo ""
    echo "${BOLD}Undo Instructions:${RESET}"
    echo "  To restore your previous configuration:"
    echo "    mv ${GITCONFIG}.bak.* $GITCONFIG"
    if [ "$GLOBAL_HOOKS" = "1" ]; then
        echo "  To remove global template directory:"
        echo "    git config --global --unset init.templateDir"
    fi

    echo ""
    echo "${BOLD}Next Steps:${RESET}"
    echo "  - Review the configuration: cat $CONFIG_DIR/config"
    echo "  - Customize ignore patterns: edit $CONFIG_DIR/ignore"
    echo "  - Customize commit template: edit $CONFIG_DIR/commit-template.txt"
    if [ "$INSTALL_HUSKY" = "1" ]; then
        echo "  - Test commit hooks in your repositories"
    fi

    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "${BOLD}Git Configuration Installer${RESET}"
    echo "Repository: https://github.com/BadRat-in/git-config"
    echo ""

    # Special case: --apply-here only installs hook in current repo
    if [ "$APPLY_HERE" = "1" ]; then
        info "Quick hook installation mode (--apply-here)"
        echo ""

        # Check if config files exist, download if needed
        if [ ! -f "$CONFIG_DIR/hooks/commit-msg.sh" ]; then
            info "Hook file not found locally, downloading..."
            check_downloader
            install_config_files
        fi

        install_standalone_hook "$(pwd)"
        exit 0
    fi

    # Run prerequisite checks
    check_downloader

    if [ "$INSTALL_HUSKY" = "1" ]; then
        check_node_npm
    fi

    # Confirm installation
    if [ "$AUTO_YES" != "1" ]; then
        echo "This script will:"
        echo "  1. Create $CONFIG_DIR directory"
        echo "  2. Download configuration files from GitHub"
        echo "  3. Backup and replace $GITCONFIG"

        if [ "$INSTALL_HUSKY" = "1" ]; then
            echo "  4. Install Husky + Commitlint + lint-staged in repositories"
        fi

        if [ "$GLOBAL_HOOKS" = "1" ]; then
            echo "  5. Set up global git template directory for hooks"
        fi

        echo ""

        if ! prompt_yes_no "Continue with installation?" "y"; then
            info "Installation cancelled"
            exit 0
        fi
    fi

    # Execute installation steps
    install_config_files
    configure_gitconfig

    if [ "$GLOBAL_HOOKS" = "1" ] && [ "$INSTALL_HUSKY" != "1" ]; then
        setup_global_hooks
    fi

    if [ "$INSTALL_HUSKY" = "1" ]; then
        install_husky_workflow
    fi

    if [ "$SETUP_SHELL_INTEGRATION" = "1" ]; then
        setup_shell_integration
    fi

    # Show summary
    show_summary
}

# Run main function
main
