#!/usr/bin/env sh
# Quick Git Hook Installer
# Installs the commit-msg validation hook into the current repository

set -e

# Colors for output
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

info() { printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$1"; }
success() { printf "%s[SUCCESS]%s %s\n" "$GREEN" "$RESET" "$1"; }
error() { printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$1" >&2; }

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    error "Not in a git repository. Please run this from within a git repo."
    exit 1
fi

GIT_DIR=$(git rev-parse --git-dir)
HOOK_SOURCE="$HOME/.config/git/hooks/commit-msg.sh"
HOOK_DEST="$GIT_DIR/hooks/commit-msg"

# Check if source hook exists
if [ ! -f "$HOOK_SOURCE" ]; then
    error "Source hook not found at: $HOOK_SOURCE"
    info "Please run the main installer first or download the hook manually."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_DIR/hooks"

# Backup existing hook if present
if [ -f "$HOOK_DEST" ]; then
    BACKUP="$HOOK_DEST.backup.$(date +%Y%m%d_%H%M%S)"
    info "Backing up existing hook to: $BACKUP"
    cp "$HOOK_DEST" "$BACKUP"
fi

# Copy and make executable
info "Installing commit-msg hook..."
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod 755 "$HOOK_DEST"

success "Commit message validation hook installed successfully!"
info "Hook location: $HOOK_DEST"
info "Try committing with an invalid message to test the hook."
