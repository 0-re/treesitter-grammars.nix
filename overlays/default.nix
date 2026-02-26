final: prev:
let
  myGrammars = import ../grammars/default.nix { pkgs = final; };
  lib = final.lib;
  libExt = final.stdenv.hostPlatform.extensions.sharedLibrary;

  grammarToEmacsLink = drv: {
    name = "lib/lib${
      lib.strings.replaceStrings [ "_" ] [ "-" ] (
        lib.strings.removeSuffix "-grammar" (lib.strings.getName drv)
      )
    }${libExt}";
    path = "${drv}/parser";
  };

  grammarToNvimLink = name: drv: {
    name = "parser/${lib.removePrefix "tree-sitter-" name}${libExt}";
    path = "${drv}/parser";
  };

  # All nixpkgs built grammars + our custom ones (deduped by attr name)
  combinedGrammars = prev.tree-sitter.builtGrammars // myGrammars;
in
{
  # Individual grammars accessible as pkgs.tree-sitter-grammars.tree-sitter-<lang>
  tree-sitter-grammars = prev.tree-sitter-grammars // myGrammars;

  # Emacs: combined nixpkgs + custom grammars with lib/libtree-sitter-<lang>.so layout
  emacs-treesit-grammars-all = final.linkFarm "emacs-treesit-grammars"
    (map grammarToEmacsLink (builtins.attrValues combinedGrammars));

  # Neovim: combined nixpkgs + custom grammars with parser/<lang>.so layout
  nvim-treesit-grammars-all = final.linkFarm "nvim-treesit-grammars"
    (lib.mapAttrsToList grammarToNvimLink combinedGrammars);
}
