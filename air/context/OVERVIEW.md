# Project Overview

## Description
A Nix flake providing a curated collection of tree-sitter grammars with automatic discovery and easy consumption patterns. Inspired by llm-agents.nix, this project uses blueprint for clean organization and provides both individual grammar packages and a combined overlay for seamless integration into NixOS configurations and development environments.

## Core Principles
- Documentation-driven development using Air
- Blueprint-based flake organization for automatic package discovery
- Consistent package structure across all grammars
- On-demand grammar updates using Nushell scripts
- Multi-platform support (Linux and macOS, x86_64 and aarch64)

## Technology Stack
- **Build System**: Nix flakes with blueprint framework
- **Package Manager**: Nix
- **Automation**: Nushell scripts for updates and maintenance
- **Target Platforms**: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **CI/CD**: GitHub Actions for build testing
- **Binary Cache**: Optional Cachix integration

## Project Structure
```
treesitter-grammars.nix/
├── flake.nix              # Blueprint-based flake definition
├── flake.lock             # Locked dependencies
├── packages/              # Tree-sitter grammar packages (auto-discovered)
│   ├── tree-sitter-nix/
│   ├── tree-sitter-nu/
│   ├── tree-sitter-astro/
│   └── ...
├── lib/                   # Shared build utilities
│   └── default.nix        # Helper functions for grammar building
├── overlays/              # Nixpkgs overlays (auto-discovered)
│   └── default.nix        # Expose all grammars
├── scripts/               # Nushell automation scripts
│   ├── update-grammar.nu
│   └── add-grammar.nu
├── devshell.nix          # Development environment
├── air/                   # Air documentation
│   ├── context/           # Project context files
│   └── *.org              # Planning documents
└── .github/
    └── workflows/         # CI/CD pipelines
```

## Architecture
The project follows the llm-agents.nix pattern using blueprint for automatic flake organization:

- **Blueprint Discovery**: Automatically maps directories to flake outputs
  - `packages/` → `packages.<system>.*`
  - `overlays/` → `overlays.*`
  - `lib/` → `lib.*`

- **Package Pattern**: Each grammar follows a consistent two-file structure
  - `default.nix`: Exports the package via callPackage
  - `package.nix`: Contains the actual derivation

- **Build System**: Uses standard Nix derivations with tree-sitter CLI
- **Update Mechanism**: Nushell scripts for manual/on-demand updates

## Core Components

### Grammar Packages
Individual tree-sitter grammar packages in `packages/tree-sitter-<language>/`:
- astro, hcl, kotlin, nix, nu, roc, sql, templ

Each package builds the grammar from source using `tree-sitter generate`.

### Shared Library (`lib/`)
Helper functions for building grammars consistently:
- `buildGrammar`: Standard grammar derivation builder
- `fetchTreeSitterGrammar`: Convenience function for fetching from GitHub

### Overlay (`overlays/`)
Nixpkgs overlay exposing all grammars under `pkgs.tree-sitter-grammars.*`

### Automation Scripts (`scripts/`)
Nushell scripts for maintenance:
- Grammar version updates
- Adding new grammars to the collection

## Document States (Air Workflow)
Air uses these predefined states to track document lifecycle:
- `draft` - Initial planning phase
- `ready` - Specification complete, ready for implementation
- `work-in-progress` - Currently being implemented
- `complete` - Implementation finished
- `dropped` - No longer needed
- `unknown` - State cannot be determined

## Getting Started

### For Users
```bash
# Try a grammar without installation
nix build github:0-re/treesitter-grammars.nix#tree-sitter-nix

# Use in a shell
nix shell github:0-re/treesitter-grammars.nix#tree-sitter-nu

# Add to flake inputs
# See README.md for full integration examples
```

### For Contributors
1. Review Air planning documents: `airctl status`
2. Check ready work: `airctl status --state ready`
3. Enter development shell: `nix develop`
4. Make changes and test: `nix flake check`
5. Update Air document states as work progresses

## Current Focus
- Initial implementation of 8 core grammars
- Blueprint-based package structure
- Nushell automation scripts
- Use `airctl status --state work-in-progress,ready` to see current priorities