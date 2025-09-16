# Aurora Copilot instructions

This document provides essential information for coding agents working with the Aurora repository to minimize exploration time and avoid common build failures.

## Repository Overview

**Aurora** is a cloud-native desktop operating system that reimagines the Linux desktop experience. It's an immutable OS built on Fedora Linux using container technologies with atomic updates.

- **Type**: Container-based Linux distribution build system 
- **Base**: Fedora Linux with KDE Plasma Desktop + Universal Blue infrastructure
- **Languages**: Bash scripts, JSON configuration, Python utilities
- **Build System**: Just (command runner), Podman/Docker containers, GitHub Actions
- **Target**: Immutable desktop OS with two variants (base + developer experience)

## Repository Structure

### Root Directory Files
- `Containerfile` - Main container build definition (multi-stage: base → dx)
- `Justfile` - Build automation recipes (33KB - like Makefile but more readable)
- `packages.json` - Package inclusion/exclusion lists per Fedora version and variant
- `.pre-commit-config.yaml` - Pre-commit hooks for basic validation
- `image-versions.yml` - Image version configurations
- `cosign.pub` - Container signing public key

### Key Directories
- `system_files/` (74MB) - User-space files, configurations, fonts, themes
- `build_files/` - Build scripts organized as base/, dx/, shared/
- `.github/workflows/` - Comprehensive CI/CD pipelines
- `just/` - Additional Just recipes for apps and system management
- `flatpaks/` - Flatpak application lists
- `iso_files/` - ISO installation configurations

### Architecture
- **Two Build Targets**: `base` (regular users) and `dx` (developer experience)
- **Image Flavors**: main, nvidia, nvidia-open, hwe variants, asus, surface
- **Fedora Versions**: 42 supported
- **Build Process**: Sequential shell scripts in build_files/ directory

## Build Instructions

### Prerequisites
**ALWAYS install these tools before attempting any builds:**

```bash
# Install Just command runner (REQUIRED for build commands, may not be available)
# If external access is limited, Just commands will not work
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Verify container runtime (usually available)
podman --version || docker --version

# Install pre-commit for validation (usually works)
pip install pre-commit
```

**Note**: In restricted environments, Just command runner may not be installable. Most validation can still be done with pre-commit and manual JSON validation.

### Essential Commands

**Build validation (ALWAYS run before making changes):**
```bash
# 1. Validate syntax and formatting (2-3 minutes)
# Note: .devcontainer.json will fail JSON check due to comments - this is expected
pre-commit run --all-files

# 2. Check specific JSON files manually:
python3 -c "import json; json.load(open('packages.json'))"

# 3. Check Just syntax (requires Just installation)
just check  # Only if Just command runner is available

# 4. Fix formatting issues automatically
just fix    # Only if Just command runner is available
```

**Build commands (use with extreme caution - these take 30+ minutes and require significant resources):**
```bash
# Build base image (30-60 minutes, requires 20GB+ disk space)
just build bluefin latest main

# Build developer variant (45-90 minutes, requires 25GB+ disk space)
just build bluefin-dx latest main

# Build with specific kernel pin
just build bluefin latest main "" "" "" "6.10.10-200.fc40.x86_64"
```

**Utility commands:**
```bash
# Clean build artifacts (if Just available)
just clean

# List all available recipes (if Just available)
just --list

# Validate image/tag/flavor combinations (if Just available)
just validate bluefin latest main
```

**Working without Just (when external access is restricted):**
```bash
# Manual validation instead of 'just check':
find . -name "*.just" -exec echo "Checking {}" \; -exec head -5 {} \;

# Manual cleanup instead of 'just clean':
rm -rf *_build* previous.manifest.json changelog.md output.env

# View Justfile recipes manually:
grep -n "^[a-zA-Z].*:" Justfile | head -20
```

### Critical Build Notes

1. **Container builds require massive resources** (20GB+ disk, 8GB+ RAM, 30+ minute runtime)
2. **Always run `just check` before making changes** - catches syntax errors early
3. **Pre-commit hooks are mandatory** - run `pre-commit run --all-files` to validate changes
4. **Never run full builds in CI unless specifically testing container changes**
5. **Use `just clean` to reset build state if encountering issues**

### Common Build Failures & Workarounds

**Pre-commit failures:**
```bash
# Known issue: .devcontainer.json contains comments (invalid for JSON checker)
# This failure is expected and can be ignored:
# ".devcontainer.json: Failed to json decode"

# Fix end-of-file and trailing whitespace automatically
pre-commit run --all-files

# Validate specific JSON files (excluding .devcontainer.json):
python3 -c "import json; json.load(open('packages.json'))"  # Should pass
```

**Just syntax errors (if Just is available):**
```bash
# Auto-fix formatting
just fix

# Manual validation
just check
```

**Container build failures:**
- Ensure adequate disk space (25GB+ free)
- Clean previous builds: `just clean` (if available)
- Check container runtime: `podman system info` or `docker system info`
- Build failures often indicate resource constraints rather than code issues

## Validation Pipeline

### Pre-commit Hooks (REQUIRED)
The repository uses mandatory pre-commit validation:
- `check-json` - Validates JSON syntax
- `check-toml` - Validates TOML syntax
- `check-yaml` - Validates YAML syntax
- `end-of-file-fixer` - Ensures files end with newline
- `trailing-whitespace` - Removes trailing whitespace

**Always run:** `pre-commit run --all-files` before committing changes.

### GitHub Actions Workflows
- `build-image-latest-main.yml` - Builds latest images on main branch changes
- `build-image-stable.yml` - Builds stable release images
- `build-image-gts.yml` - Builds GTS (Go-To-Stable) images
- `reusable-build.yml` - Core build logic for all image variants

### Manual Validation Steps
1. `pre-commit run --all-files` - Runs validation hooks (2-3 minutes, .devcontainer.json failure is expected)
2. `python3 -c "import json; json.load(open('packages.json'))"` - Validate critical JSON files
3. `just check` - Validates Just syntax (if Just is available, 30 seconds)
4. `just fix` - Auto-fixes formatting issues (if Just is available, 30 seconds)
5. Test builds only if making container-related changes (30+ minutes)

## Package Management

### packages.json Structure
The `packages.json` file defines package inclusion/exclusion per Fedora version:
```json
{
  "all": {
    "include": {
      "all": ["package1", "package2"],  // Base image packages
      "dx": ["dev-package1", "dev-package2"]  // Developer additions
    },
    "exclude": {
      "all": ["unwanted-package"],
      "dx": []
    }
  },
  "42": {  // Fedora 41 specific overrides
    "include": {"all": ["fedora41-only-package"]},
    "exclude": {"all": []}
  }
}
```