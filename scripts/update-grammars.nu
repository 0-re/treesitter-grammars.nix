#!/usr/bin/env nu

# Update all tree-sitter grammar versions
def main [] {
    print "Updating tree-sitter grammars..."

    # Find all JSON files in grammars directory
    let grammar_files = (ls grammars/*.json | get name)

    for file in $grammar_files {
        let name = ($file | path basename | str replace ".json" "")

        # Read existing JSON to get the repo URL
        let existing = (open $file)
        let repo = ($existing.url | str replace "https://github.com/" "")

      print $"Updating ($name) from \"($repo)\"..."
        update_json_grammar $name $repo
    }

    print "\n✅ All grammars updated successfully!"
}

# Update a single grammar JSON file
def update_json_grammar [name: string, repo: string] {
    let parts = ($repo | split row "/")
    let owner = $parts.0
    let repo_name = $parts.1

    # Fetch latest commit hash
    let api_url = $"https://api.github.com/repos/($repo)/commits/HEAD"
    let rev = http get $api_url | get sha

    # Use nix-prefetch-github to get the hash (positional args: owner repo)
    let prefetch_result = (
        nix-prefetch-github $owner $repo_name --rev $rev
        | from json
    )

    # Write JSON file
    {
        url: $"https://github.com/($repo)",
        rev: $rev,
        sha256: $prefetch_result.hash,
        fetchLFS: false,
        fetchSubmodules: false,
        deepClone: false,
        leaveDotGit: false
    } | to json | save -f $"grammars/($name).json"

    print $"  ✓ Updated ($name) to ($rev | str substring 0..7)"
}
