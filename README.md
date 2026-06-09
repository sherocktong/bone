# bone

A lightweight macOS note companion app inspired by [Tot](https://tot.rocks). It lives in your system tray, offers 7 persistent text buffers with automatic saving, and features vim-like modal editing.

## Features

- **macOS native** — Built with Swift, SwiftUI, and AppKit
- **System tray icon** — Always accessible from the menu bar
- **7 color-coded buffers** — Switch instantly via dots or ⌘1–⌘7
- **Automatic saving** — Every keystroke is debounced and persisted to `~/Library/Application Support/bone/`
- **Find & Replace** — Native find bar with ⌘F, match highlighting, and replace
- **Close-to-hide** — Clicking the close button hides the window; the app keeps running in the tray

## Vim Commands

| Mode | Command | Action |
|------|---------|--------|
| Normal | `h` `j` `k` `l` | Move left/down/up/right |
| Normal | `w` / `b` | Next / previous word |
| Normal | `0` / `$` | Start / end of line |
| Normal | `gg` / `G` | Top / bottom of file |
| Normal | `i` | Enter Insert mode |
| Normal | `a` | Enter Insert mode (after cursor) |
| Normal | `o` / `O` | Open new line below / above |
| Normal | `x` | Delete character |
| Normal | `dd` | Delete line |
| Normal | `yy` | Yank (copy) line |
| Normal | `p` | Paste |
| Normal | `u` / `U` | Undo / Redo |
| Normal | `v` | Enter Visual mode |
| Visual | `h` `j` `k` `l` | Extend selection |
| Visual | `d` / `x` | Delete selection |
| Visual | `y` | Copy selection |
| Any | `Esc` | Return to Normal mode |

## Build & Run

### Using Swift Package Manager

```bash
swift build
swift run bone
```

### Create an Xcode Project (recommended for distribution)

1. Open **Xcode** → File → New → Project → macOS → App
2. Name it **bone**, set interface to **SwiftUI**, language to **Swift**
3. Replace the generated source files with the contents of `Sources/bone/`
4. Drag `Resources/AppIcon.appiconset` into **Assets.xcassets**
5. Drag `Resources/StatusBarIcon.imageset` into **Assets.xcassets**
6. Update `StatusBarController.swift` to load the custom icon:

```swift
if let image = NSImage(named: "StatusBarIcon") {
    button.image = image
    button.image?.size = NSSize(width: 18, height: 18)
    button.image?.isTemplate = true
}
```

7. Build and run with **⌘R**

## Project Structure

```
bone/
├── Package.swift                      # Swift Package manifest
├── Sources/bone/
│   ├── boneApp.swift                  # App entry point & lifecycle
│   ├── StatusBarController.swift      # NSStatusBar menu & tray logic
│   ├── WindowManager.swift            # Window show/hide/close override
│   ├── Models/
│   │   └── Buffer.swift               # Buffer data model (Codable)
│   ├── Services/
│   │   └── BufferStore.swift          # JSON persistence & auto-save
│   ├── ViewModels/
│   │   └── AppViewModel.swift         # Buffer selection & state
│   └── Views/
│       ├── ContentView.swift          # Main window layout
│       ├── BufferSelectorView.swift   # 7-dot top bar
│       └── VimTextView.swift          # Vim modal text editor
├── Resources/
│   ├── AppIcon.appiconset/            # macOS app icon (all sizes)
│   ├── StatusBarIcon.imageset/        # Menu bar template icon
│   └── bone_icon.svg                  # Source vector icon
└── generate_icons.py                  # Script to regenerate icons
```

## Data Storage

Buffers are saved as 7 individual JSON files to:

```
~/Library/Application Support/bone/buffers/
```

Each file is written atomically (temp file + move) to prevent corruption.

## License

MIT
