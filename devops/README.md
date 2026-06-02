# DevOps

This directory contains build, packaging, and deployment automation for the **bone** macOS app.

## Scripts

### `scripts/package.sh`

Builds the release binary and creates distributable macOS packages.

#### Usage

```bash
# Build .app bundle only (default)
./devops/scripts/package.sh

# Build .app + .dmg (drag-and-drop installer)
./devops/scripts/package.sh --dmg

# Build .app + .pkg (system installer)
./devops/scripts/package.sh --pkg

# Build .app + .dmg + .pkg
./devops/scripts/package.sh --all
```

#### Output

All artifacts are written to `.build/package/`:

| Artifact | Description |
|----------|-------------|
| `bone.app` | macOS application bundle (binary + resources + Info.plist) |
| `bone-1.0.0.dmg` | Disk image with app + `/Applications` symlink |
| `bone-1.0.0.pkg` | Installer package for system-wide installation |

#### What the script does

1. **Build** — Compiles the Swift package in release mode (`swift build -c release`)
2. **Bundle** — Creates a standard `.app` bundle structure:
   - `Contents/MacOS/bone` — release binary
   - `Contents/Info.plist` — generated from template with bundle metadata
   - `Contents/Resources/` — app icons and status bar icons
3. **Package** — Optionally creates `.dmg` or `.pkg` from the bundle

#### Customization

Edit the variables at the top of `package.sh`:

```bash
APP_NAME="bone"                           # App display name
BUNDLE_ID="com.bingtong.bone"             # Unique bundle identifier
```

## Future Additions

- `scripts/sign.sh` — Code signing with Apple Developer ID
- `scripts/notarize.sh` — Notarization for Gatekeeper compatibility
- `scripts/sparkle.sh` — Auto-update feed generation
- `.github/workflows/` — GitHub Actions CI/CD pipeline
