{ pkgs }:

# A standalone tree-sitter package with all 0-re custom grammars
pkgs.tree-sitter.override {
  extraGrammars = {
    # Override nixpkgs grammars with our pinned versions from JSON
    tree-sitter-astro = pkgs.lib.importJSON ../../grammars/astro.json;
    tree-sitter-hcl = pkgs.lib.importJSON ../../grammars/hcl.json;
    tree-sitter-kotlin = pkgs.lib.importJSON ../../grammars/kotlin.json;
    tree-sitter-nix = pkgs.lib.importJSON ../../grammars/nix.json;
    tree-sitter-nu = pkgs.lib.importJSON ../../grammars/nu.json;
    tree-sitter-roc = pkgs.lib.importJSON ../../grammars/roc.json;
    tree-sitter-sql = pkgs.lib.importJSON ../../grammars/sql.json;
    tree-sitter-templ = pkgs.lib.importJSON ../../grammars/templ.json;
  };
}
