{
  description = "Curated collection of tree-sitter grammars packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let
      blueprint-outputs = inputs.blueprint { inherit inputs; };
    in
    blueprint-outputs // {
      # Manually expose overlay since blueprint doesn't auto-discover overlays
      overlays.default = import ./overlays/default.nix;
    };
}
