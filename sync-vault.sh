#!/bin/bash
# Mirror your Obsidian vault into Quartz's content/ folder.
#
# Workflow: edit notes in Obsidian -> run `npm run sync` (or this script)
# -> review with `git status` -> commit & push. GitHub Actions builds
# and deploys the site automatically.
#
# Only notes with `publish: true` in their frontmatter end up on the
# site (see the explicit-publish plugin in quartz.config.yaml), so your
# private notes, dailies and ToDo stay local even though they're synced.
set -euo pipefail

VAULT="$HOME/Projects/Obsidian_Vault"
CONTENT="$(cd "$(dirname "$0")" && pwd)/content"

if [ ! -d "$VAULT" ]; then
  echo "error: vault not found at $VAULT" >&2
  exit 1
fi

rsync -av --delete \
  --exclude='.obsidian/' \
  --exclude='.trash/' \
  --exclude='.DS_Store' \
  --exclude='*.code-workspace' \
  "$VAULT/" "$CONTENT/"

echo "synced $VAULT -> $CONTENT"
