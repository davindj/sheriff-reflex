# AI Portfolio — Sheriff Shooter

This SwiftUI demo is a small shooter-style app that uses the camera and Apple's Vision hand-pose detection to let the player `point`/`shoot` targets using a hand gesture. It is intended as a portfolio/demo app showing simple real-time computer vision integration with SwiftUI game logic.

## What it does

- Uses the device camera and Vision hand-pose model to detect a pointing gesture and trigger a "shoot" event.
- Displays moving targets, tracks score and lives, and plays basic hit/miss interactions.
- Includes a minimal game manager and UI implemented with SwiftUI.

## Key symbols / files

- `ai_portfolioApp.swift` — app entry point
- `ContentView.swift` — main UI, game layout, and camera/hand-pose view integration
- `CameraHandDetector` / `CameraHandDetectionView` — camera capture + Vision-based hand-pose detection (in `ContentView.swift`)
- `GameManager`, `Target` — lightweight game logic and models (in `ContentView.swift`)
- `ai_portfolio.entitlements` — entitlements (camera) used by the app
- `Assets.xcassets` — app icons and colors

Open these files in Xcode to inspect or modify behavior.

## Requirements

- Xcode (latest stable recommended)
- macOS with a camera (for testing hand-pose detection) or a real iOS device
- Swift 5+

## Quick start

1. Open the project in Xcode:

```bash
cd /path/to/ai-portfolio
open ai-portfolio.xcodeproj
```

2. Select a simulator or a connected device and Run (⌘R). Note: camera and Vision testing requires a real device or a webcam-enabled simulator.

3. Alternatively build from terminal:

```bash
xcodebuild -scheme ai-portfolio -workspace ai-portfolio.xcodeproj -sdk iphonesimulator -configuration Debug build
```

## Permissions

This app uses the camera. Ensure camera permission strings are added in the project settings / `Info.plist` if you extend the app. The provided `ai_portfolio.entitlements` indicates camera capability requirements.

## Extending the project

- Add additional Vision models or hand-gesture classification for more robust controls.
- Extract camera/vision code into a reusable module for other SwiftUI projects.
- Add UI polish, sounds, and score persistence.

## Development notes

- The current implementation places camera and game logic together for simplicity; consider separating responsibilities for larger features.

## Commit

After reviewing changes locally:

```bash
git add README.md
git commit -m "Improve README: describe shooter game and camera/Vision usage"
git push
```

---
If you'd like, I can add a `LICENSE`, include screenshots, or generate a brief architecture diagram — tell me which and I'll update the README.
# AI Portfolio

Small SwiftUI iOS/macOS portfolio app showcasing simple AI-related UI components.

## Overview

This repository contains a minimal SwiftUI project (`ai-portfolio`) intended as a personal portfolio/demo app. It includes the app entry, a primary content view, and asset catalogs.

## Requirements

- macOS with Xcode installed (open with latest stable Xcode recommended)
- Swift 5/

## Quick start

1. Open the project in Xcode:

```
cd /path/to/ai-portfolio
open ai-portfolio.xcodeproj
```

2. Select a simulator or a connected device and press Run (⌘R).

Alternatively, build from terminal:

```
xcodebuild -scheme ai-portfolio -workspace ai-portfolio.xcodeproj -sdk iphonesimulator -configuration Debug build
```

## Project structure

- `ai_portfolioApp.swift` — App entry point
- `ContentView.swift` — Main SwiftUI view
- `Assets.xcassets/` — Colors and app icons
- `ai-portfolio.xcodeproj/` — Xcode project files

## Notes

- Entitlements are present in `ai_portfolio.entitlements` for app capabilities.
- This repo is intended as a simple demo; expand features as needed.

## Commits

After reviewing, commit the new README locally:

```
git add README.md
git commit -m "Add README"
git push
```

## Author

davindjayadi
