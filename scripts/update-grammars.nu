#!/usr/bin/env nu

# Update all tree-sitter grammar versions
def main [] {
    print "Updating tree-sitter grammars..."

    # All grammars with their repository paths
    let grammars = [
        { name: "astro", repo: "virchau13/tree-sitter-astro" },
        { name: "hcl", repo: "MichaHoffmann/tree-sitter-hcl" },
        { name: "kotlin", repo: "fwcd/tree-sitter-kotlin" },
        { name: "nix", repo: "nix-community/tree-sitter-nix" },
        { name: "nu", repo: "nushell/tree-sitter-nu" },
        { name: "roc", repo: "faldor20/tree-sitter-roc" },
        { name: "sql", repo: "DerekStride/tree-sitter-sql" },
        { name: "templ", repo: "vrischmann/tree-sitter-templ" }
    ]

    for grammar in $grammars {
        print $"Updating ($grammar.name)..."
        update_json_grammar $grammar.name $grammar.repo
    }

    print "\n✅ All grammars updated successfully!"
}

# Update a single grammar JSON file
def update_json_grammar [name: string, repo: string] {
    let url = $"https://github.com/($repo)"
    let api_url = $"https://api.github.com/repos/($repo)/commits/HEAD"

    # Fetch latest commit hash
    let rev = (
        http get $api_url
        | get sha
    )

    # Use nix-prefetch-git to get the hash
    let hash = (
        nix-prefetch-git --url $url --rev $rev
        | from json
        | get hash
    )

    # Create JSON content
    let json_content = {
        url: $url,
        rev: $rev,
        sha256: $hash,
        fetchLFS: false,
        fetchSubmodules: false,
        deepClone: false,
        leaveDotGit: false
    }

    # Write to file
    let json_file = $"grammars/($name).json"
    $json_content | to json | save -f $json_file

    print $"  ✓ Updated ($name) to ($rev | str substring 0..7)"
}
