#!/usr/bin/env bash

# ============================================================
# Apply GitHub Branch Protection
# Reusable script for any repo and branch
# ============================================================

# Show help
usage() {
  echo ""
  echo "Usage:"
  echo "  $0 <TOKEN> <USER> <REPO> <BRANCH> <JSON_FILE>"
  echo ""
  echo "Example:"
  echo "  $0 ghp_123TOKENabc rafaelberto banking-account main branch-protection.json"
  echo ""
  exit 1
}

# Validate number of parameters
if [ "$#" -ne 5 ]; then
  echo "❌ Error: Missing parameters."
  usage
fi

TOKEN="$1"
USER="$2"
REPO="$3"
BRANCH="$4"
JSON_FILE="$5"

# Check if JSON file exists
if [ ! -f "$JSON_FILE" ]; then
  echo "❌ Error: JSON file '$JSON_FILE' not found."
  exit 1
fi

echo ""
echo "🔐 Applying branch protection..."
echo "-----------------------------------------------"
echo "User:       $USER"
echo "Repository: $REPO"
echo "Branch:     $BRANCH"
echo "JSON File:  $JSON_FILE"
echo "-----------------------------------------------"
echo ""

# Execute request
curl -X PUT \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USER/$REPO/branches/$BRANCH/protection" \
  -d @"$JSON_FILE"

echo ""
echo "✅ Done!"
