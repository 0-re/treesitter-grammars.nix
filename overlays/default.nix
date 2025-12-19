final: prev: {
  tree-sitter = prev.tree-sitter.override {
    extraGrammars = {
      # Override nixpkgs grammars with our pinned versions from JSON
      tree-sitter-astro = final.lib.importJSON ../grammars/astro.json;
      tree-sitter-hcl = final.lib.importJSON ../grammars/hcl.json;
      tree-sitter-kotlin = final.lib.importJSON ../grammars/kotlin.json;
      tree-sitter-nix = final.lib.importJSON ../grammars/nix.json;
      tree-sitter-nu = final.lib.importJSON ../grammars/nu.json;
      tree-sitter-roc = final.lib.importJSON ../grammars/roc.json;
      tree-sitter-sql = final.lib.importJSON ../grammars/sql.json;
      tree-sitter-templ = final.lib.importJSON ../grammars/templ.json;
    };
  };
}
