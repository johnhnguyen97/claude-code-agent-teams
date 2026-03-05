#!/bin/bash
# Read a Gitea Wiki page and output markdown content
# Usage: gitea_wiki_read.sh <page-name>
#
# Examples:
#   bash scripts/gitea_wiki_read.sh Home
#   bash scripts/gitea_wiki_read.sh "SpaceDB-Reconstruction"
#   bash scripts/gitea_wiki_read.sh --list   # List all pages

set -e

PAGE="${1:?Usage: gitea_wiki_read.sh <page-name|--list>}"

GITEA_URL="${GITEA_URL:-http://localhost:3000}"
GITEA_REPO="${GITEA_REPO:-your-user/your-repo}"
GITEA_AUTH="${GITEA_AUTH:?Set GITEA_AUTH=user:password}"

if [ "$PAGE" = "--list" ]; then
    # List all wiki pages
    curl -s -u "$GITEA_AUTH" \
        "$GITEA_URL/api/v1/repos/$GITEA_REPO/wiki/pages" | \
        /c/Python312/python.exe -c "
import sys, json
pages = json.load(sys.stdin)
for p in pages:
    title = p.get('title', 'unknown')
    sub = p.get('sub_url', '')
    print(f'  {title:<30} ({sub})')
"
else
    # Read specific page content
    curl -s -u "$GITEA_AUTH" \
        "$GITEA_URL/api/v1/repos/$GITEA_REPO/wiki/page/$PAGE" | \
        /c/Python312/python.exe -c "
import sys, json, base64
data = json.load(sys.stdin)
if 'content_base64' in data:
    content = base64.b64decode(data['content_base64']).decode('utf-8')
    print(content)
elif 'message' in data:
    print(f'Error: {data[\"message\"]}', file=sys.stderr)
    sys.exit(1)
else:
    print('Error: Unexpected response format', file=sys.stderr)
    sys.exit(1)
"
fi
