#!/bin/bash

# 変更されたファイルからリストを生成
BULLET_LIST=""
for file in $CHANGED_FILES; do
  BULLET_LIST="$BULLET_LIST
- $file"
done

# issue の本文を作成
BODY="$DESCRIPTION

Files changed in update:$BULLET_LIST"

# ラベルが存在するか確認し、なければ作成
if ! gh api repos/$GH_REPO/labels/$LABEL_NAME --silent 2>/dev/null; then
  echo "Creating $LABEL_NAME label..."
  gh api repos/$GH_REPO/labels -F name="$LABEL_NAME" -F color="$LABEL_COLOR" -F description="Auto update for Lean dependencies"
fi

# issue を作成
gh issue create --title "$TITLE" --body "$BODY" --label "$LABEL_NAME"
