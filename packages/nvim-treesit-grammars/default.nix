{ pkgs }:

let
  lib = pkgs.lib;
  grammars = import ../../grammars/default.nix { inherit pkgs; };
  libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
  grammarNames = builtins.attrNames grammars;
  langName = name: lib.removePrefix "tree-sitter-" name;
in
# Neovim: parser/<lang>.so
# Matches nvim-treesitter parser directory convention
pkgs.linkFarm "nvim-treesit-grammars" (
  map (name:
    let drv = grammars.${name};
    in {
      name = "parser/${langName name}${libExt}";
      path = "${drv}/parser";
    }
  ) grammarNames
)
