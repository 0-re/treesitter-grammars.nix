#!/usr/bin/env nu

# Update tree-sitter grammar JSON files to latest versions
# Requires: jq, curl, nix-prefetch-github (available via devshell)

const GRAMMARS_DIR = "grammars"

# Update a single grammar
def update-grammar [name: string]: nothing -> record<updated: bool, change: string> {
    let json_file = $"($GRAMMARS_DIR)/($name).json"
    
    if not ($json_file | path exists) {
        print $"Warning: ($json_file) not found, skipping"
        return { updated: false, change: "" }
    }
    
    # Read existing JSON
    let existing = open $json_file
    let url = $existing.url
    let current_rev = $existing.rev
    
    # Extract owner/repo from URL
    let repo = $url | str replace "https://github.com/" ""
    let parts = $repo | split row "/"
    let owner = $parts.0
    let repo_name = $parts.1
    
    print $"Checking ($name) from ($repo)..."
    
    # Get latest commit SHA
    let api_url = $"https://api.github.com/repos/($repo)/commits/HEAD"
    let headers = if ($env.GITHUB_TOKEN? | is-not-empty) {
        [Authorization $"Bearer ($env.GITHUB_TOKEN)"]
    } else {
        []
    }
    
    let latest_rev = try {
        http get $api_url --headers $headers | get sha
    } catch {
        print $"  Error: Failed to fetch latest commit for ($repo)"
        return { updated: false, change: "" }
    }
    
    # Check if update needed
    if $current_rev == $latest_rev {
        print $"  Already up to date \(($current_rev | str substring 0..7)\)"
        return { updated: false, change: "" }
    }
    
    print $"  Updating: ($current_rev | str substring 0..7) -> ($latest_rev | str substring 0..7)"
    
    # Get the new hash using nix-prefetch-github
    let prefetch_result = try {
        nix-prefetch-github $owner $repo_name --rev $latest_rev | from json
    } catch {
        print "  Error: Failed to calculate hash"
        return { updated: false, change: "" }
    }
    
    let hash = $prefetch_result.hash
    
    # Update JSON file, preserving other fields like 'generate'
    let updated_json = $existing | upsert rev $latest_rev | upsert sha256 $hash
    $updated_json | to json | save -f $json_file
    
    print $"  ✓ Updated to ($latest_rev | str substring 0..7)"
    
    let change = $"- **($name)**: ($current_rev | str substring 0..7) → ($latest_rev | str substring 0..7)"
    { updated: true, change: $change }
}

# Main entry point
def main [
    --grammars: string = ""  # Specific grammars to update (space-separated, empty for all)
]: nothing -> nothing {
    print "=== Tree-sitter Grammar Updater ==="
    print ""
    
    # Get list of grammars to update
    let grammars_to_update = if ($grammars | is-not-empty) {
        $grammars | split row " " | where { $in | is-not-empty }
    } else {
        glob $"($GRAMMARS_DIR)/*.json" 
        | each { path basename | str replace ".json" "" }
    }
    
    print $"Updating ($grammars_to_update | length) grammar\(s\)..."
    print ""
    
    # Update each grammar and collect results
    let results = $grammars_to_update | each { |name| update-grammar $name }
    
    let updated = ($results | where updated | length) > 0
    let changes = $results | where updated | get change | str join "\n"
    
    print ""
    print "=== Update Complete ==="
    
    # Set outputs for GitHub Actions
    if ($env.GITHUB_OUTPUT? | is-not-empty) {
        $"updated=($updated)" | save --append $env.GITHUB_OUTPUT
        "changes<<EOF" | save --append $env.GITHUB_OUTPUT
        $changes | save --append $env.GITHUB_OUTPUT
        "EOF" | save --append $env.GITHUB_OUTPUT
    }
    
    if $updated {
        print ""
        print "Changes:"
        print $changes
    } else {
        print "No updates needed."
    }
}
