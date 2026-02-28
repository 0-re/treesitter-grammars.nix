{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.nushell
    pkgs.nix-prefetch-github
    pkgs.nix-prefetch-git
    pkgs.nixpkgs-fmt
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
