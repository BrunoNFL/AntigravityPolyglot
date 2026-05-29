#!/bin/bash

# Antigravity AntigravityPolyglot: Local Context Sync
# This script copies global skill resources to the local .gemini/ directory
# to work around Antigravity's limitation in accessing subfolders of global skills.

SKILL_NAME=$1
SUBFOLDER=$2

if [ -z "$SKILL_NAME" ] || [ -z "$SUBFOLDER" ]; then
    echo "Usage: ./local_context_sync.sh <skill-name> <subfolder-relative-path>"
    exit 1
fi

GLOBAL_SKILL_PATH="$HOME/.gemini/skills/$SKILL_NAME"
LOCAL_GEMINI_DIR=".agents/skills/$SKILL_NAME"

if [ ! -d "$GLOBAL_SKILL_PATH/$SUBFOLDER" ]; then
    echo "Error: Subfolder '$SUBFOLDER' not found in global skill '$SKILL_NAME'."
    exit 1
fi

echo "Syncing global skill resources to local context..."
mkdir -p "$LOCAL_GEMINI_DIR"
cp -r "$GLOBAL_SKILL_PATH/$SUBFOLDER" "$LOCAL_GEMINI_DIR/"

echo "Success: Subfolder '$SUBFOLDER' from skill '$SKILL_NAME' is now available locally at '$LOCAL_GEMINI_DIR/$SUBFOLDER'."
echo "Antigravity can now access these resources using project-relative paths (nested under .agents/)."


