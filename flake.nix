{
  description = "Curated collection of tree-sitter grammars packaged with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      blueprint-outputs = inputs.blueprint { inherit inputs; };
      
      # Systems to support
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper to generate per-system attributes
      forAllSystems = f: inputs.nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import inputs.nixpkgs { inherit system; };
        inherit system;
      });
      
      # Build grammar packages for each system
      grammarPackages = forAllSystems ({ pkgs, ... }:
        import ./grammars/default.nix { inherit pkgs; }
      );
    in
    blueprint-outputs
    // {
      # Expose overlay
      overlays.default = import ./overlays/default.nix;
      
      # Expose individual grammar packages
      packages = inputs.nixpkgs.lib.genAttrs systems (system:
        (blueprint-outputs.packages.${system} or {})
        // grammarPackages.${system}
      );
    };
}
