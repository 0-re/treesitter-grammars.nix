{
  description = "Curated collection of tree-sitter grammars packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.blueprint { inherit inputs; }
    // {
      overlays.default = import ./overlays/default.nix;
    };
}
