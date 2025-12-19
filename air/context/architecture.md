# System Architecture

## Core Philosophy

This project provides a curated collection of tree-sitter grammars packaged with Nix, following the llm-agents.nix organizational pattern. The architecture emphasizes simplicity, consistency, and ease of use through blueprint's automatic discovery system.

## Design Principles

### Blueprint-Based Organization
- Automatic discovery of packages, overlays, and libraries
- Convention over configuration for flake structure
- Each grammar is an independent package in `packages/`
- Minimal boilerplate in `flake.nix`

### Consistent Package Structure
- Every grammar follows the same two-file pattern:
  - `default.nix`: Simple callPackage export
  - `package.nix`: Standard derivation with metadata
- Shared helper functions in `lib/` for common build logic
- Uniform metadata (description, homepage, license, platforms)

### On-Demand Updates
- Manual updates using Nushell scripts rather than automated CI
- Updates driven by actual needs, not scheduled runs
- Nushell provides cross-platform scripting with good ergonomics
- Simple update workflow: fetch latest, compute hash, update package

### Multi-Platform Support
- Build on Linux (x86_64, aarch64) and macOS (x86_64, aarch64)
- CI testing ensures cross-platform compatibility
- Platform-specific fixes documented in individual packages

### Easy Consumption
- Multiple usage patterns: direct flake inputs, overlay, ad-hoc
- Nixpkgs overlay for convenient access to all grammars
- Clear examples in documentation
- Works with NixOS, nix-darwin, and home-manager

## System Architecture

```
treesitter-grammars.nix/
├── flake.nix                    # Blueprint entry point
├── flake.lock                   # Locked dependencies
├── packages/                    # Grammar packages (blueprint auto-discovery)
│   ├── tree-sitter-astro/
│   │   ├── default.nix         # CallPackage export
│   │   └── package.nix         # Derivation definition
│   ├── tree-sitter-hcl/
│   ├── tree-sitter-kotlin/
│   ├── tree-sitter-nix/
│   ├── tree-sitter-nu/
│   ├── tree-sitter-roc/
│   ├── tree-sitter-sql/
│   └── tree-sitter-templ/
├── lib/                         # Shared utilities
│   └── default.nix             # buildGrammar, fetchTreeSitterGrammar
├── overlays/                    # Nixpkgs overlays (blueprint auto-discovery)
│   └── default.nix             # tree-sitter-grammars attribute set
├── scripts/                     # Nushell automation
│   ├── update-grammar.nu       # Update specific grammar
│   └── add-grammar.nu          # Add new grammar to collection
├── devshell.nix                # Development environment
├── air/                         # Documentation
│   ├── context/                # Project context files
│   ├── tree-sitter-grammar-automation-with-nix-flake.org
│   └── ...
└── .github/
    └── workflows/
        └── build.yml           # CI: build and test
```

### Package Layer
- **Purpose**: Individual tree-sitter grammar packages
- **Responsibilities**: Build grammars from source, install parser files
- **Design**: Standard Nix derivations using tree-sitter CLI

### Library Layer
- **Purpose**: Shared build logic for all grammars
- **Responsibilities**: Provide helper functions to reduce boilerplate
- **Design**: Reusable functions with sensible defaults

### Overlay Layer
- **Purpose**: Integration with nixpkgs ecosystem
- **Responsibilities**: Expose all grammars under unified namespace
- **Design**: Standard Nixpkgs overlay pattern

### Automation Layer
- **Purpose**: Grammar maintenance and updates
- **Responsibilities**: Fetch versions, compute hashes, update packages
- **Design**: Nushell scripts for cross-platform compatibility

## Core Components

### 1. Blueprint Framework Integration

Blueprint provides automatic flake organization by mapping directories to outputs:

```nix
# flake.nix - minimal configuration
{
  description = "Curated collection of tree-sitter grammars packaged with Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
```

Blueprint automatically discovers:
- `packages/tree-sitter-*/` → `packages.<system>.tree-sitter-*`
- `overlays/` → `overlays.default`
- `lib/` → `lib.*`
- `devshell.nix` → `devShells.<system>.default`

### 2. Grammar Package Structure

Each grammar follows a consistent two-file pattern:

```nix
# packages/tree-sitter-<language>/default.nix
{ callPackage }:
callPackage ./package.nix { }
```

```nix
# packages/tree-sitter-<language>/package.nix
{ lib, stdenv, fetchFromGitHub, tree-sitter }:

stdenv.mkDerivation rec {
  pname = "tree-sitter-<language>";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "<sha256-hash>";
  };

  nativeBuildInputs = [ tree-sitter ];

  buildPhase = ''
    tree-sitter generate
  '';

  installPhase = ''
    mkdir -p $out/parser
    cp -r src/parser.c src/tree_sitter $out/parser/
  '';

  meta = with lib; {
    description = "Tree-sitter grammar for <language>";
    homepage = "<homepage>";
    license = licenses.<license>;
    platforms = platforms.unix;
  };
}
```

### 3. Shared Library Functions

The `lib/default.nix` provides helper functions to reduce boilerplate:

```nix
{ lib, stdenv, tree-sitter, fetchFromGitHub }:

rec {
  # Build a tree-sitter grammar from source
  buildGrammar = {
    language,
    version,
    src,
    location ? null,  # For grammars in subdirectories
    generate ? true,  # Whether to run tree-sitter generate
    ...
  }@args: stdenv.mkDerivation ({
    pname = "tree-sitter-${language}";
    inherit version src;
    nativeBuildInputs = [ tree-sitter ];
    # ... build and install phases
  } // removeAttrs args [ "language" "generate" "location" ]);

  # Fetch from tree-sitter organization
  fetchTreeSitterGrammar = {
    language,
    version,
    hash,
    repo ? "tree-sitter-${language}",
    ...
  }@args: fetchFromGitHub ({
    owner = "tree-sitter";
    inherit repo;
    rev = "v${version}";
    inherit hash;
  } // removeAttrs args [ "language" "version" "hash" "repo" ]);
}
```

### 4. Overlay System

The overlay exposes all grammars under a unified namespace:

```nix
# overlays/default.nix
final: prev: {
  tree-sitter-grammars = {
    inherit (final)
      tree-sitter-astro
      tree-sitter-hcl
      tree-sitter-kotlin
      tree-sitter-nix
      tree-sitter-nu
      tree-sitter-roc
      tree-sitter-sql
      tree-sitter-templ
      ;
  };
}
```

This allows users to access grammars via `pkgs.tree-sitter-grammars.tree-sitter-nix`.

### 5. Automation Scripts (Nushell)

Nushell scripts provide cross-platform automation:

**update-grammar.nu**: Update a specific grammar
- Fetch latest release from GitHub API
- Compute new hash using nix-prefetch-git
- Update package.nix with new version and hash

**add-grammar.nu**: Add a new grammar to the collection
- Create package directory structure
- Generate default.nix and package.nix from template
- Fetch initial version and hash from GitHub

## Technology Stack

### Build System and Tooling
- **Nix**: Reproducible builds and package management
- **Blueprint**: Flake organization and automatic discovery
- **tree-sitter CLI**: Grammar generation from source
- **nix-prefetch-git**: Computing content hashes for sources

### Automation and Scripting
- **Nushell**: Cross-platform scripting for updates and maintenance
- **GitHub API**: Fetching latest grammar releases
- **GitHub Actions**: CI/CD for build testing

### Development Tools
- **nixpkgs-fmt**: Nix code formatting
- **nix flake check**: Build validation
- **direnv**: Automatic development environment loading

### Supported Platforms
- **x86_64-linux**: Linux on x86_64
- **aarch64-linux**: Linux on ARM64
- **x86_64-darwin**: macOS on Intel
- **aarch64-darwin**: macOS on Apple Silicon

## Performance Considerations

### Build Performance
- Each grammar is independently built for parallel compilation
- Blueprint's lazy evaluation ensures only requested packages are built
- Nix's content-addressed store provides efficient caching
- Binary cache (Cachix) can eliminate compilation entirely

### Update Efficiency
- Nushell scripts minimize external process calls
- GitHub API rate limits respected with conditional requests
- Hash computation only when version changes detected
- Manual updates avoid unnecessary CI overhead

## Error Handling Strategy

### Build Errors
- Each grammar build failure is isolated to that package
- Clear error messages from tree-sitter CLI
- Platform-specific build issues documented in package.nix
- Fallback to nixpkgs grammars if needed

### Update Script Errors
- GitHub API failures: retry with exponential backoff
- Hash mismatch: clear error with re-fetch instructions
- Version not found: suggest manual version specification
- Network issues: graceful failure with informative messages

## Future Considerations

### Potential Extensions
- More grammars added on-demand based on usage
- Automated testing of parsers with sample code
- Integration with editor configuration (Neovim, Emacs, VS Code)
- Upstreaming improvements to nixpkgs tree-sitter grammars

### Maintenance
- Regular dependency updates (nixpkgs, blueprint)
- Monitor upstream grammar repositories for breaking changes
- Community contributions for new grammars
- Documentation improvements based on user feedback