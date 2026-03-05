#!/bin/bash
# Push a markdown file to Gitea Wiki
# Usage: gitea_wiki_push.sh <page-name> <markdown-file> [commit-message]
#
# Examples:
#   bash scripts/gitea_wiki_push.sh "SpaceDB-Reconstruction" docs/spacedb-s2d.md
#   bash scripts/gitea_wiki_push.sh "GAGEpack-Recovery" docs/gagepack-recovery.md "doc-sync: update FK chains"

set -e

PAGE="${1:?Usage: gitea_wiki_push.sh <page-name> <markdown-file> [commit-message]}"
FILE="${2:?Usage: gitea_wiki_push.sh <page-name> <markdown-file> [commit-message]}"
MSG="${3:-auto-sync from doc-sync}"

GITEA_URL="${GITEA_URL:-http://localhost:3000}"
GITEA_REPO="${GITEA_REPO:-your-user/your-repo}"
GITEA_AUTH="${GITEA_AUTH:?Set GITEA_AUTH=user:password}"

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Base64 encode the file content (use -w0 for no line wrapping)
CONTENT=$(base64 -w0 "$FILE")

# Check if page exists
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$GITEA_AUTH" \
    "$GITEA_URL/api/v1/repos/$GITEA_REPO/wiki/page/$PAGE")

if [ "$STATUS" = "200" ]; then
    # Update existing page
    RESPONSE=$(curl -s -X PATCH \
        -u "$GITEA_AUTH" \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"$PAGE\",\"content_base64\":\"$CONTENT\",\"message\":\"$MSG\"}" \
        "$GITEA_URL/api/v1/repos/$GITEA_REPO/wiki/page/$PAGE")
    echo "Updated wiki page: $PAGE"
else
    # Create new page
    RESPONSE=$(curl -s -X POST \
        -u "$GITEA_AUTH" \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"$PAGE\",\"content_base64\":\"$CONTENT\",\"message\":\"$MSG\"}" \
        "$GITEA_URL/api/v1/repos/$GITEA_REPO/wiki/pages")
    echo "Created wiki page: $PAGE"
fi

# Check for errors
if echo "$RESPONSE" | grep -q '"message"'; then
    ERROR=$(echo "$RESPONSE" | /c/Python312/python.exe -c "import sys,json; print(json.load(sys.stdin).get('message',''))" 2>/dev/null)
    if [ -n "$ERROR" ]; then
        echo "Warning: $ERROR"
    fi
fi
