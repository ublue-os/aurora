# Aurora Container Linux Distribution

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

Aurora is a Universal Blue KDE desktop experience built on Fedora Linux using container technology. It creates immutable desktop images with multiple variants and flavors for different hardware configurations.

## Working Effectively

### Prerequisites and Dependencies
- Install just command runner v1.36+ (REQUIRED for group syntax support):
  ```bash
  curl -sSLO https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz
  tar -zxvf just-1.36.0-x86_64-unknown-linux-musl.tar.gz
  sudo mv just /usr/local/bin/just
  chmod +x /usr/local/bin/just
  ```
- Podman or Docker for container operations (podman preferred)
- Python 3.x for changelog scripts
- Network access for pulling container images and verification

### Essential Commands
- Bootstrap and validate repository:
  ```bash
  just check      # Validate just syntax - takes <1 second
  just fix        # Fix just syntax formatting if needed - takes <1 second
  just clean      # Clean build artifacts - takes <1 second
  just --list     # Show all available commands and groups
  ```

### Container Image Building
**WARNING: Container builds require network access and take 45-90 minutes. NEVER CANCEL. Set timeout to 120+ minutes.**

- Build Aurora base image:
  ```bash
  # Build standard Aurora (NEVER CANCEL - takes 60-90 minutes)
  just build aurora-dx latest main 0 0 0
  
  # Build with rechunking (adds 15-30 minutes)
  just build-rechunk aurora-dx latest flavor
  ```

- Available image types:
  - `aurora` - Base KDE desktop
  - `aurora-dx` - Developer experience variant with additional tools

- Available flavors:
  - `main` - Standard configuration
  - `nvidia` - NVIDIA proprietary drivers
  - `nvidia-open` - NVIDIA open source drivers  
  - `hwe` - Hardware enablement (newer kernels)
  - Plus combinations: `hwe-nvidia`, `asus`, `surface`, etc.

- Available tags:
  - `latest` - Latest builds from main branch
  - `stable` - Stable release builds
  - `beta` - Beta testing builds

### Container Operations
- Run built container:
  ```bash
  just run aurora-dx latest main    # Runs interactive bash session
  ```

- Build validation:
  ```bash
  just validate aurora-dx latest main    # Validate image/tag/flavor combination
  ```

### ISO Building (Advanced)
**WARNING: ISO builds take 30-45 minutes. NEVER CANCEL. Set timeout to 60+ minutes.**
```bash
just build-iso aurora latest main    # Build installable ISO
just run-iso aurora latest main      # Test ISO in virtual environment
```

## Network Dependencies and Limitations

### What requires network access:
- Container image pulls from ghcr.io/ublue-os 
- Container signature verification with cosign
- Package installations during builds
- Changelog generation (pulls remote manifests)

### What works offline:
- Just syntax validation (`just check`, `just fix`)
- Repository cleanup (`just clean`)
- File structure navigation
- Configuration validation

### Common network-related failures:
```bash
# These commands will fail without network access:
just build aurora-dx latest main     # Fails pulling base images
just verify-container                 # Fails downloading cosign
just changelogs                      # Fails pulling manifests
```

## Validation and Testing

### Always run before committing changes:
```bash
just check                           # Validate just syntax
```

### Manual validation scenarios:
After making changes to build scripts or configurations:
1. Validate just syntax: `just check`
2. Test image building (if network available): `just build aurora-dx latest main`
3. Verify container runs: `just run aurora-dx latest main`
4. Test key functionality inside container (if applicable)

### CI/CD validation:
- All builds are validated in GitHub Actions
- Builds include security scanning and signature verification
- Multi-architecture support (x86_64 primarily)

## Project Structure

### Key directories:
```
/home/runner/work/aurora/aurora/
├── .github/               # GitHub workflows and automation
│   ├── workflows/         # CI/CD build pipelines  
│   └── changelogs.py      # Automated changelog generation
├── build_files/           # Container build scripts
│   ├── base/              # Base image build steps
│   ├── dx/                # Developer experience additions
│   └── shared/            # Common build utilities
├── system_files/          # Files installed into images
│   ├── shared/            # Common system configurations
│   └── dx/                # Developer experience specific files
├── just/                  # Just command definitions
│   ├── aurora-apps.just   # Application management commands
│   └── aurora-system.just # System configuration commands
├── Justfile               # Main just command definitions
├── Containerfile          # Main container build definition
├── packages.json          # Package installation definitions
└── flatpaks/              # Flatpak application lists
```

### Important files to check when making changes:
- `Justfile` - Main build commands and workflows
- `packages.json` - Package installations by Fedora version
- `Containerfile` - Container build definition
- `build_files/shared/build-base.sh` - Base image build process
- `build_files/shared/build-dx.sh` - Developer experience build process

## Common Tasks and Timing

### Syntax validation and formatting:
```bash
just check    # <1 second - check all justfile syntax
just fix      # <1 second - auto-fix formatting issues  
just --list   # <1 second - show all available commands
```

### Container builds (NETWORK REQUIRED):
```bash
# NEVER CANCEL: Basic build takes 60-90 minutes. Set timeout to 120+ minutes.
just build aurora-dx latest main

# NEVER CANCEL: Build with rechunking takes 75-120 minutes. Set timeout to 150+ minutes.  
just build-rechunk aurora-dx latest main

# NEVER CANCEL: ISO building takes 30-45 minutes. Set timeout to 60+ minutes.
just build-iso aurora latest main
```

### Development workflow:
1. Make changes to relevant files
2. Run `just check` to validate syntax (<1 second)
3. Run `just fix` if syntax issues found (<1 second)
4. If changing build scripts, test build process (60-90 minutes with network)
5. Commit changes

## Build Failures and Troubleshooting

### Network connectivity issues:
```bash
# Error: "dial tcp: lookup cgr.dev on 127.0.0.53:53: server misbehaving"
# Solution: This indicates network restrictions. Container builds require internet access.
```

### Just syntax errors:
```bash
# Error: "Unknown attribute `group`"
# Solution: Upgrade to just v1.36+ which supports the group attribute
```

### Validation failures:
```bash
# Error: "Invalid Image..." or "Invalid tag..." or "Invalid flavor..."
# Solution: Check valid combinations in Justfile images/tags/flavors definitions
```

## Known Limitations in Restricted Environments

- Container builds fail without network access (cannot pull base images)
- Container verification fails without network access (cannot download cosign)
- Changelog generation fails without network access (cannot pull manifests)
- Use syntax validation and file editing workflows for offline development
- Full build testing requires environment with network access

## Additional Resources

- [Aurora Documentation](https://docs.getaurora.dev/)
- [Universal Blue Contributing Guide](https://universal-blue.org/contributing.html)
- [Local Building Guide](https://docs.getaurora.dev/guides/building)
- [Discussions](https://universal-blue.discourse.group/c/aurora/11)