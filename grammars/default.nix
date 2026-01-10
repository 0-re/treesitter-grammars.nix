{ pkgs }:
let
  lib = pkgs.lib;

  # Parse GitHub URL to owner/repo
  parseGitHubUrl = url:
    let
      # Remove https://github.com/ prefix
      path = lib.removePrefix "https://github.com/" url;
      parts = lib.splitString "/" path;
    in {
      owner = lib.elemAt parts 0;
      repo = lib.elemAt parts 1;
    };

  # Helper to build a single grammar
  buildGrammar = name: json:
    let
      parsed = parseGitHubUrl json.url;
    in
    pkgs.tree-sitter.buildGrammar ({
      language = name;
      version = "0.0.0+rev=${lib.substring 0 7 json.rev}";
      src = pkgs.fetchFromGitHub {
        inherit (parsed) owner repo;
        rev = json.rev;
        hash = json.sha256;
        fetchSubmodules = json.fetchSubmodules or false;
      };
      meta = {
        description = "Tree-sitter grammar for ${name}";
        homepage = json.url;
      };
    } // lib.optionalAttrs (json ? generate) {
      generate = json.generate;
    } // lib.optionalAttrs (json ? location) {
      location = json.location;
    });

  # Load all JSON files in the current directory
  grammarFiles = lib.filterAttrs 
    (name: type: type == "regular" && lib.hasSuffix ".json" name) 
    (builtins.readDir ./.);

  # Function to load a specific JSON and build it
  loadAndBuild = filename:
    let
      name = lib.removeSuffix ".json" filename;
      json = lib.importJSON (./. + "/${filename}");
    in
      {
        name = "tree-sitter-${name}";
        value = buildGrammar name json;
      };

  grammars = lib.listToAttrs (map loadAndBuild (builtins.attrNames grammarFiles));
in
  grammars
