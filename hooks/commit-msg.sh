#!/usr/bin/env sh
# POSIX commit-msg hook (standalone) - validates Conventional Commits basic rules
# Exit codes:
#   0 = success, 1 = validation failed
#
# This hook validates commit messages against Conventional Commits specification:
# https://www.conventionalcommits.org/

MSG_FILE="$1"

# Ensure arg is present
if [ -z "$MSG_FILE" ]; then
  printf "ERROR: No commit message file provided.\n" >&2
  exit 1
fi

# Ensure file exists and is readable
if [ ! -f "$MSG_FILE" ] || [ ! -r "$MSG_FILE" ]; then
  printf "ERROR: Cannot read commit message file: %s\n" "$MSG_FILE" >&2
  exit 1
fi

# Read first non-empty line (subject), skipping blank lines
SUBJECT=""
while IFS= read -r line || [ -n "$line" ]; do
  # Remove carriage return and trim whitespace
  line="$(printf "%s" "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  if [ -n "$line" ]; then
    SUBJECT="$line"
    break
  fi
done < "$MSG_FILE"

# Check if subject is empty
if [ -z "$SUBJECT" ]; then
  printf "✖ Commit message is empty. Provide a subject line.\n" >&2
  exit 1
fi

# Allow merge commits and reverts to pass through without validation
case "$SUBJECT" in
  Merge\ *|Revert\ *|Revert\ \"*\")
    exit 0
    ;;
esac

# Allowed types (must match commit-template-txt)
TYPES="feat|fix|docs|chore|refactor|perf|test|ci|style|deploy|debug"

# Validate format: type(scope)?: subject
# - Type must be from allowed list
# - Scope is optional, lowercase alphanumeric with ._- allowed
# - Colon and space required after type/scope
# - Subject should be 1-72 characters
TYPE_RE="^(${TYPES})"
SCOPE_RE="(\([a-z0-9._-]+\))?"
SEPARATOR_RE=": "
SUBJECT_RE=".{1,72}$"

FULL_RE="${TYPE_RE}${SCOPE_RE}${SEPARATOR_RE}${SUBJECT_RE}"

# Validate the commit message format
if ! printf "%s" "$SUBJECT" | grep -Eq "$FULL_RE"; then
  printf "✖ Commit message does not follow Conventional Commits format.\n\n" >&2
  printf "Expected format: <type>(<scope>)?: <short summary>\n\n" >&2
  printf "Allowed types:\n" >&2
  printf "  feat, fix, docs, chore, refactor, perf, test, ci, style, deploy, debug\n\n" >&2
  printf "Examples:\n" >&2
  printf "  feat: add user authentication\n" >&2
  printf "  fix(api): resolve null pointer error\n" >&2
  printf "  docs: update installation guide\n\n" >&2
  printf "Your subject line:\n" >&2
  printf "  %s\n\n" "$SUBJECT" >&2

  # Provide specific hints based on common errors
  if ! printf "%s" "$SUBJECT" | grep -Eq "^(${TYPES})"; then
    printf "Hint: Subject must start with a valid type (e.g., feat, fix, docs)\n" >&2
  elif ! printf "%s" "$SUBJECT" | grep -q ": "; then
    printf "Hint: Type must be followed by a colon and space (': ')\n" >&2
  elif [ "$(printf "%s" "$SUBJECT" | wc -c)" -gt 72 ]; then
    printf "Hint: Subject line is too long (max 72 characters)\n" >&2
  fi

  exit 1
fi

# Check that subject doesn't end with a period
if printf "%s" "$SUBJECT" | grep -q '\.$'; then
  printf "✖ Subject line should not end with a period.\n" >&2
  exit 1
fi

# Ensure subject starts with lowercase (convention for imperative mood)
SUBJECT_TEXT="$(printf "%s" "$SUBJECT" | sed 's/^[^:]*: //')"
FIRST_CHAR="$(printf "%s" "$SUBJECT_TEXT" | cut -c1)"

if printf "%s" "$FIRST_CHAR" | grep -q '[A-Z]'; then
  printf "✖ Subject should start with lowercase (imperative mood convention).\n" >&2
  printf "   Example: 'feat: add feature' not 'feat: Add feature'\n" >&2
  exit 1
fi

# Check for BREAKING CHANGE usage (if present, require proper formatting)
if grep -qi 'BREAKING CHANGE' "$MSG_FILE"; then
  # Ensure "BREAKING CHANGE:" (with colon) exists and has text after colon
  BC_LINE="$(grep -i 'BREAKING CHANGE' "$MSG_FILE" | head -n 1 || true)"

  case "$BC_LINE" in
    *:*)
      # Ensure there's non-whitespace after colon
      DESCRIPTION="$(printf "%s" "$BC_LINE" | sed 's/^[^:]*://;s/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [ -z "$DESCRIPTION" ]; then
        printf "✖ 'BREAKING CHANGE:' must include a description after the colon.\n" >&2
        printf "   Example: 'BREAKING CHANGE: remove support for Node 12'\n" >&2
        exit 1
      fi
      ;;
    *)
      printf "✖ Use 'BREAKING CHANGE: <description>' (include colon and description).\n" >&2
      printf "   Example: 'BREAKING CHANGE: remove support for Node 12'\n" >&2
      exit 1
      ;;
  esac
fi

# Enforce minimum subject length
MIN_LENGTH=10
SUBJECT_LENGTH=$(printf "%s" "$SUBJECT_TEXT" | wc -c | tr -d ' ')

if [ "$SUBJECT_LENGTH" -lt "$MIN_LENGTH" ]; then
  printf "✖ Subject is too short (minimum %d characters, got %d).\n" "$MIN_LENGTH" "$SUBJECT_LENGTH" >&2
  printf "   Be more descriptive about the change.\n" >&2
  printf "   Example: 'feat: add user authentication module'\n" >&2
  exit 1
fi

# All validation checks passed
exit 0
