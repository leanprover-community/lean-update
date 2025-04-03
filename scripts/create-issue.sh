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

# Create the body of the issue
BODY="$DESCRIPTION

Files changed in update:$BULLET_LIST

## Build Output

\`\`\`
$BUILD_OUTPUT
\`\`\`
"

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
