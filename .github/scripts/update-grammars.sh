#!/usr/bin/env bash
set -euo pipefail

# Update tree-sitter grammar JSON files to latest versions

GRAMMARS_DIR="grammars"
CHANGES=""
UPDATED="false"

update_grammar() {
    local name="$1"
    local json_file="$GRAMMARS_DIR/$name.json"
    
    if [[ ! -f "$json_file" ]]; then
        echo "Warning: $json_file not found, skipping"
        return
    fi
    
    # Extract repo URL and current rev
    local url
    url=$(jq -r '.url' "$json_file")
    local current_rev
    current_rev=$(jq -r '.rev' "$json_file")
    
    # Extract owner/repo from URL
    local repo
    repo="${url#https://github.com/}"
    
    echo "Checking $name from $repo..."
    
    # Get latest commit SHA
    local latest_rev
    latest_rev=$(curl -sL \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN:-}" \
        "https://api.github.com/repos/$repo/commits/HEAD" | jq -r '.sha')
    
    if [[ "$latest_rev" == "null" || -z "$latest_rev" ]]; then
        echo "  Error: Failed to fetch latest commit for $repo"
        return
    fi
    
    # Check if update needed
    if [[ "$current_rev" == "$latest_rev" ]]; then
        echo "  Already up to date (${current_rev:0:7})"
        return
    fi
    
    echo "  Updating: ${current_rev:0:7} -> ${latest_rev:0:7}"
    
    # Get the new hash using nix-prefetch-git
    local hash
    hash=$(nix-prefetch-git --url "$url" --rev "$latest_rev" --quiet 2>/dev/null | jq -r '.sha256')
    
    if [[ -z "$hash" || "$hash" == "null" ]]; then
        echo "  Error: Failed to calculate hash"
        return
    fi
    
    # Update JSON file
    jq --arg rev "$latest_rev" --arg hash "$hash" \
        '.rev = $rev | .sha256 = $hash' \
        "$json_file" > "${json_file}.tmp"
    mv "${json_file}.tmp" "$json_file"
    
    echo "  ✓ Updated to ${latest_rev:0:7}"
    CHANGES="${CHANGES}- **$name**: ${current_rev:0:7} → ${latest_rev:0:7}\n"
    UPDATED="true"
}

main() {
    echo "=== Tree-sitter Grammar Updater ==="
    echo ""
    
    # Get list of grammars to update
    local grammars_to_update=()
    
    if [[ -n "${GRAMMARS:-}" ]]; then
        # Specific grammars requested
        IFS=' ' read -ra grammars_to_update <<< "$GRAMMARS"
    else
        # All grammars
        for json_file in "$GRAMMARS_DIR"/*.json; do
            [[ -f "$json_file" ]] || continue
            local name
            name=$(basename "$json_file" .json)
            grammars_to_update+=("$name")
        done
    fi
    
    echo "Updating ${#grammars_to_update[@]} grammar(s)..."
    echo ""
    
    for grammar in "${grammars_to_update[@]}"; do
        update_grammar "$grammar"
    done
    
    echo ""
    echo "=== Update Complete ==="
    
    # Set outputs for GitHub Actions
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "updated=$UPDATED" >> "$GITHUB_OUTPUT"
        # Escape newlines for GitHub Actions
        CHANGES_ESCAPED="${CHANGES//$'\n'/'%0A'}"
        CHANGES_ESCAPED="${CHANGES_ESCAPED//'%0A%0A'/'%0A'}"
        echo "changes<<EOF" >> "$GITHUB_OUTPUT"
        echo -e "$CHANGES" >> "$GITHUB_OUTPUT"
        echo "EOF" >> "$GITHUB_OUTPUT"
    fi
    
    if [[ "$UPDATED" == "true" ]]; then
        echo ""
        echo "Changes:"
        echo -e "$CHANGES"
    else
        echo "No updates needed."
    fi
}

main "$@"
