{ pkgs }:

let
  myGrammars = import ../../grammars/default.nix { inherit pkgs; };
in
# A standalone tree-sitter package with all 0-re custom grammars linked
(pkgs.tree-sitter.override {
  webUISupport = true;
}).withPlugins (_: builtins.attrValues myGrammars)
