#!/bin/sh
# Comprehensive test suite for commit-msg hook
# Tests all validation rules including minimum length

echo "=== Commit Hook Validation Tests ==="
echo ""

HOOK_PATH="/Users/ravindra/.config/git/hooks/commit-msg.sh"
pass=0
fail=0
total=0

# Helper function to run test
run_test() {
  test_num=$1
  description=$2
  commit_msg=$3
  should_pass=$4

  total=$((total + 1))

  printf "%s" "$commit_msg" > t.txt

  if $HOOK_PATH t.txt 2>/dev/null; then
    result="passed"
  else
    result="failed"
  fi

  if [ "$should_pass" = "yes" ] && [ "$result" = "passed" ]; then
    echo "✓ Test $test_num: $description"
    pass=$((pass + 1))
  elif [ "$should_pass" = "no" ] && [ "$result" = "failed" ]; then
    echo "✓ Test $test_num: $description"
    pass=$((pass + 1))
  else
    echo "✗ Test $test_num: $description FAILED (expected $should_pass, got $result)"
    fail=$((fail + 1))
  fi
}

# ============================================================================
# VALID COMMIT MESSAGES (should pass)
# ============================================================================

run_test 1 "Valid commit with sufficient length" \
  "feat: add user authentication module" "yes"

run_test 2 "Valid commit with scope" \
  "fix(api): resolve null pointer error" "yes"

run_test 3 "Debug type accepted" \
  "debug: fix memory leak in parser" "yes"

run_test 4 "Minimum length exactly 10 chars" \
  "feat: 0123456789" "yes"

run_test 5 "Style type with description" \
  "style: format code according to eslint" "yes"

run_test 6 "Chore type with description" \
  "chore: update dependencies to latest" "yes"

run_test 7 "Docs type with description" \
  "docs: update installation guide" "yes"

# Test 8: BREAKING CHANGE with proper format
total=$((total + 1))
printf "feat: add new api endpoints\n\nBREAKING CHANGE: remove old API endpoints" > t.txt
if $HOOK_PATH t.txt 2>/dev/null; then
  echo "✓ Test 8: BREAKING CHANGE with proper format"
  pass=$((pass + 1))
else
  echo "✗ Test 8: BREAKING CHANGE with proper format FAILED"
  fail=$((fail + 1))
fi

# ============================================================================
# BYPASS CASES (should pass without validation)
# ============================================================================

run_test 9 "Merge commit bypassed" \
  "Merge branch 'feature' into main" "yes"

run_test 10 "Revert commit bypassed" \
  'Revert "feat: add feature"' "yes"

run_test 11 "Merge with PR number" \
  "Merge pull request #123 from user/branch" "yes"

# ============================================================================
# INVALID FORMAT (should fail)
# ============================================================================

run_test 12 "Invalid format - no type" \
  "just a regular message" "no"

run_test 13 "Invalid format - missing colon" \
  "feat add new feature" "no"

run_test 14 "Invalid format - missing space after colon" \
  "feat:add new feature" "no"

run_test 15 "Invalid type" \
  "feature: add new functionality" "no"

# ============================================================================
# LENGTH VALIDATION (should fail if too short)
# ============================================================================

run_test 16 "Too short - 9 chars" \
  "feat: 012345678" "no"

run_test 17 "Too short - 5 chars" \
  "feat: abcde" "no"

run_test 18 "Too short - 1 char" \
  "feat: x" "no"

run_test 19 "Too short with scope" \
  "fix(api): fix" "no"

# ============================================================================
# FORMATTING RULES (should fail)
# ============================================================================

run_test 20 "Uppercase start - should fail" \
  "feat: Add new feature module" "no"

run_test 21 "Trailing period - should fail" \
  "feat: add new feature." "no"

run_test 22 "Multiple trailing periods" \
  "feat: add new feature..." "no"

# ============================================================================
# LENGTH LIMITS (should fail if too long)
# ============================================================================

run_test 23 "Subject too long (>72 chars)" \
  "feat: this is an extremely long commit message that definitely exceeds the maximum allowed character count" "no"

# ============================================================================
# BREAKING CHANGE VALIDATION (should fail if malformed)
# ============================================================================

# Test 24: BREAKING CHANGE without colon
total=$((total + 1))
printf "feat: new feature\n\nBREAKING CHANGE no colon here" > t.txt
if $HOOK_PATH t.txt 2>/dev/null; then
  echo "✗ Test 24: BREAKING CHANGE without colon FAILED (should reject)"
  fail=$((fail + 1))
else
  echo "✓ Test 24: BREAKING CHANGE without colon"
  pass=$((pass + 1))
fi

# Test 25: BREAKING CHANGE with empty description
total=$((total + 1))
printf "feat: new feature\n\nBREAKING CHANGE: " > t.txt
if $HOOK_PATH t.txt 2>/dev/null; then
  echo "✗ Test 25: BREAKING CHANGE with empty description FAILED (should reject)"
  fail=$((fail + 1))
else
  echo "✓ Test 25: BREAKING CHANGE with empty description"
  pass=$((pass + 1))
fi

# ============================================================================
# EDGE CASES
# ============================================================================

run_test 26 "Empty message" \
  "" "no"

run_test 27 "Only whitespace" \
  "   " "no"

run_test 28 "Valid with numbers in scope" \
  "fix(api-v2): resolve authentication issue" "yes"

run_test 29 "Valid with underscore in scope" \
  "feat(user_auth): implement oauth2 flow" "yes"

run_test 30 "Valid with hyphen in scope" \
  "fix(db-connection): handle timeout errors" "yes"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=== Test Results ==="
echo "Total:  $total"
echo "Passed: $pass"
echo "Failed: $fail"
echo ""

if [ $fail -eq 0 ]; then
  echo "✓ All $total tests passed!"
  exit 0
else
  echo "✗ $fail out of $total tests failed"
  exit 1
fi
