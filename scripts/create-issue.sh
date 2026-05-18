#!/bin/bash

# Generate a list of changed files
BULLET_LIST=""
for file in $CHANGED_FILES; do
  BULLET_LIST="$BULLET_LIST
- $file"
done

# Get directory contents
DIR_CONTENTS=$(ls -la)
echo "Directory contents: $DIR_CONTENTS"

# Run lake build and capture its output
# Using || true to ensure the script continues even if lake build fails
BUILD_OUTPUT=$(lake build --log-level=warning 2>&1 || true)

# Truncate variable sections if necessary to keep the full BODY within GitHub's
# 65536-character limit, while preserving the build output code block.
HEADER="$DESCRIPTION

Files changed in update:$BULLET_LIST
"
BUILD_PREFIX="

## Build Output

\`\`\`
"
BUILD_SUFFIX="
\`\`\`
"
TRUNCATION_NOTICE="
...(truncated)"
MAX_BODY_LEN=65536
FIXED_LEN=$((${#BUILD_PREFIX} + ${#BUILD_SUFFIX}))
AVAILABLE=$((MAX_BODY_LEN - ${#HEADER} - FIXED_LEN))
if [ $AVAILABLE -lt 0 ]; then
  HEADER_AVAILABLE=$((MAX_BODY_LEN - FIXED_LEN))
  if [ $HEADER_AVAILABLE -gt ${#TRUNCATION_NOTICE} ]; then
    HEADER="${HEADER:0:$((HEADER_AVAILABLE - ${#TRUNCATION_NOTICE}))}$TRUNCATION_NOTICE"
  else
    HEADER="${HEADER:0:$HEADER_AVAILABLE}"
  fi
  AVAILABLE=0
fi
if [ ${#BUILD_OUTPUT} -gt $AVAILABLE ]; then
  if [ $AVAILABLE -gt ${#TRUNCATION_NOTICE} ]; then
    TRUNCATE_AT=$((AVAILABLE - ${#TRUNCATION_NOTICE}))
    BUILD_OUTPUT="${BUILD_OUTPUT:0:$TRUNCATE_AT}$TRUNCATION_NOTICE"
  else
    BUILD_OUTPUT="${BUILD_OUTPUT:0:$AVAILABLE}"
  fi
fi

# Create the body of the issue
BODY="$HEADER$BUILD_PREFIX$BUILD_OUTPUT$BUILD_SUFFIX"

# Check if the label exists, create it if not
if ! gh api repos/$GH_REPO/labels/$LABEL_NAME --silent 2>/dev/null; then
  echo "Creating $LABEL_NAME label..."
  gh api repos/$GH_REPO/labels -F name="$LABEL_NAME" -F color="$LABEL_COLOR" -F description="Auto update for Lean dependencies"
fi

# Check if an open issue with the same label already exists
if gh issue list --label "$LABEL_NAME" --state open --json number | grep -q "number"; then
  echo "An open issue with label '$LABEL_NAME' already exists. Skipping issue creation."
else
  # Create the issue
  gh issue create --title "$TITLE" --body "$BODY" --label "$LABEL_NAME"
fi
