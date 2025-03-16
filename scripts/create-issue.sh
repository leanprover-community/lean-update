#!/bin/bash

# Generate a list of changed files
BULLET_LIST=""
for file in $CHANGED_FILES; do
  BULLET_LIST="$BULLET_LIST
- $file"
done

# Create the body of the issue
BODY="$DESCRIPTION

Files changed in update:$BULLET_LIST"

# Check if the label exists, create it if not
if ! gh api repos/$GH_REPO/labels/$LABEL_NAME --silent 2>/dev/null; then
  echo "Creating $LABEL_NAME label..."
  gh api repos/$GH_REPO/labels -F name="$LABEL_NAME" -F color="$LABEL_COLOR" -F description="Auto update for Lean dependencies"
fi

# Create the issue
gh issue create --title "$TITLE" --body "$BODY" --label "$LABEL_NAME"
