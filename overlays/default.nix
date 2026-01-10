final: prev:
let
  myGrammars = import ../grammars/default.nix { pkgs = final; };
in
{
  # Add our grammars to tree-sitter-grammars
  tree-sitter-grammars = prev.tree-sitter-grammars // myGrammars;

  # Convenience: tree-sitter with all our grammars linked
  tree-sitter-with-all-grammars = prev.tree-sitter.withPlugins (p: 
    (builtins.attrValues myGrammars) ++ prev.tree-sitter.allGrammars
  );
}
