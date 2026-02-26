{ pkgs }:

let
  lib = pkgs.lib;
  grammars = import ../../grammars/default.nix { inherit pkgs; };
  libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
  grammarNames = builtins.attrNames grammars;
  langName = name: lib.removePrefix "tree-sitter-" name;
in
# Emacs: lib/libtree-sitter-<lang>.so
# Matches nixpkgs emacsPackages.treesit-grammars convention
pkgs.linkFarm "emacs-treesit-grammars" (
  map (name:
    let drv = grammars.${name};
    in {
      name = "lib/libtree-sitter-${langName name}${libExt}";
      path = "${drv}/parser";
    }
  ) grammarNames
)
