{ pkgs }:

let
  lib = pkgs.lib;
  customGrammars = import ../../grammars/default.nix { inherit pkgs; };
  libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;

  # All nixpkgs grammars + our custom ones (custom wins on conflict)
  allGrammars = pkgs.tree-sitter.builtGrammars // customGrammars;
  grammarNames = builtins.attrNames allGrammars;
  langName = name: lib.removePrefix "tree-sitter-" name;
in
# Emacs: lib/libtree-sitter-<lang>.so
# Matches nixpkgs emacsPackages.treesit-grammars convention
pkgs.linkFarm "emacs-treesit-grammars" (
  map (
    name:
    let
      drv = allGrammars.${name};
    in
    {
      name = "lib/libtree-sitter-${langName name}${libExt}";
      path = "${drv}/parser";
    }
  ) grammarNames
)
