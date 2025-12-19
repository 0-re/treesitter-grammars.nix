# Implementation Guide

## Development Environment

### Prerequisites
- **Nix**: Nix package manager with flakes enabled
  ```bash
  # Enable flakes in ~/.config/nix/nix.conf
  experimental-features = nix-command flakes
  ```
- **direnv**: For automatic environment loading (optional but recommended)
- **Git**: Version control

### Environment Setup
```bash
# Clone repository
git clone https://github.com/0-re/treesitter-grammars.nix
cd treesitter-grammars.nix

# Enter development shell (loads all tools)
nix develop

# Or use direnv for automatic loading
direnv allow
```

### Development Shell Tools
The `devshell.nix` provides:
- `nushell` - Scripting automation
- `tree-sitter` - Grammar generation CLI
- `nodejs` - Required by some grammars
- `nixpkgs-fmt` - Nix code formatting
- `nix-update` - Version update helper
- `nix-prefetch-git` - Hash computation

### Project Structure
```
packages/                 # Grammar packages (one per subdirectory)
  tree-sitter-<lang>/
    default.nix          # CallPackage export
    package.nix          # Derivation definition
lib/                     # Shared utilities
  default.nix            # buildGrammar, fetchTreeSitterGrammar
overlays/                # Nixpkgs overlays
  default.nix            # Expose all grammars
scripts/                 # Nushell automation
  update-grammar.nu      # Update specific grammar
  add-grammar.nu         # Add new grammar
```

## Coding Standards

### Nix Code Style
- **Formatting**: Use `nixpkgs-fmt` for consistent formatting
  ```bash
  nixpkgs-fmt **/*.nix
  ```
- **Indentation**: 2 spaces (enforced by nixpkgs-fmt)
- **Line Length**: Keep lines under 100 characters when practical
- **Attribute Sets**: Align `=` for readability in multi-line sets

### Package Structure
Every grammar package must include:
1. **default.nix**: Simple callPackage export
   ```nix
   { callPackage }:
   callPackage ./package.nix { }
   ```

2. **package.nix**: Standard derivation with:
   - Metadata (`pname`, `version`, `src`)
   - Build inputs (`nativeBuildInputs = [ tree-sitter ]`)
   - Build and install phases
   - Complete `meta` attribute set

### Meta Attributes
Always include in `meta`:
- `description` - Clear, concise grammar description
- `homepage` - Link to grammar repository
- `license` - Correct SPDX license identifier
- `platforms` - Usually `platforms.unix`
- `maintainers` - Optional, for active maintainers

### Version Management
- Use exact versions from upstream releases
- Pin with `rev = "v${version}"` for reproducibility
- Always include `hash` (use `nix-prefetch-git` or `nix-hash`)
- Document version update process in package if non-standard

### Documentation
- Comment non-obvious build flags or patches
- Document platform-specific workarounds
- Include upstream links for issue references
- Keep comments concise and relevant

## Development Practices

### Adding a New Grammar

1. **Research the grammar**:
   ```bash
   # Find the grammar repository
   # Typical pattern: https://github.com/tree-sitter/tree-sitter-<language>
   ```

2. **Create package structure**:
   ```bash
   mkdir -p packages/tree-sitter-<language>
   cd packages/tree-sitter-<language>
   ```

3. **Create default.nix**:
   ```nix
   { callPackage }:
   callPackage ./package.nix { }
   ```

4. **Create package.nix**:
   - Copy template from existing grammar
   - Update metadata (name, version, source)
   - Fetch initial hash: `nix-prefetch-git <repo-url>`
   - Test build: `nix build .#tree-sitter-<language>`

5. **Update overlay**:
   ```nix
   # Add to overlays/default.nix
   tree-sitter-<language>
   ```

### Testing Strategy

#### Build Testing
```bash
# Test specific grammar
nix build .#tree-sitter-nix

# Test all grammars
nix flake check

# Test with verbose output
nix build --print-build-logs .#tree-sitter-nu
```

#### Cross-Platform Testing
```bash
# Test on different systems (if available)
nix build .#tree-sitter-nix --system x86_64-linux
nix build .#tree-sitter-nix --system aarch64-linux
nix build .#tree-sitter-nix --system x86_64-darwin
nix build .#tree-sitter-nix --system aarch64-darwin
```

#### Integration Testing
```bash
# Test overlay integration
nix eval .#overlays.default
nix eval .#lib.buildGrammar

# Test in actual editor (Neovim example)
nix shell .#tree-sitter-nix -c nvim
```

### Update Workflow

1. **Check for updates**:
   ```bash
   # Using Nushell script (when available)
   nu scripts/update-grammar.nu tree-sitter-nix
   ```

2. **Manual update process**:
   ```bash
   # Find latest release
   curl -s https://api.github.com/repos/tree-sitter/tree-sitter-nix/releases/latest | jq -r '.tag_name'

   # Compute new hash
   nix-prefetch-git --url https://github.com/tree-sitter/tree-sitter-nix --rev <tag>

   # Update package.nix with new version and hash
   # Test build
   nix build .#tree-sitter-nix
   ```

3. **Verify changes**:
   ```bash
   # Format code
   nixpkgs-fmt **/*.nix

   # Run flake check
   nix flake check
   ```

### Git Workflow

```bash
# Create feature branch
git checkout -b add-tree-sitter-<language>

# Make changes

# Commit with descriptive message
git commit -m "feat: add tree-sitter-<language> package"

# or
git commit -m "chore: update tree-sitter-nix to v1.2.3"

# Push and create PR
git push origin add-tree-sitter-<language>
```

### Commit Message Convention
- `feat:` - New grammar package
- `chore:` - Version updates, maintenance
- `fix:` - Bug fixes, build issues
- `docs:` - Documentation updates
- `ci:` - CI/CD changes