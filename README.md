# MoveMouse for macOS

MoveMouse is a native SwiftUI menu bar app for macOS that keeps your Mac awake the same way many Windows "move mouse" utilities do. It watches for idle time, nudges the pointer by a tiny amount, and can also hold a power assertion to prevent idle sleep while the app is active.

## What it does

- Runs as a lightweight menu bar utility.
- Nudges the cursor only after your Mac has been idle for the interval you choose.
- Optionally restores the pointer to its original position after each nudge.
- Optionally prevents both display sleep and system idle sleep while active.
- Lets you limit activity to a daily time window, including overnight schedules.

## Requirements

- macOS 13 or newer
- Swift 6 / current Apple Command Line Tools

## Run from source

```bash
swift run MoveMouse
```

## Build the executable

```bash
swift build
```

## Package a real `.app`

```bash
./Scripts/create-app-bundle.sh
```

The bundled app is created at `dist/MoveMouse.app`.

## First launch note

macOS requires Accessibility permission before any app can post synthetic cursor movement events. On first launch:

1. Start MoveMouse.
2. Click `Request Accessibility Access` if the permission card appears.
3. Enable MoveMouse in `System Settings > Privacy & Security > Accessibility`.

## Project layout

- `Sources/MoveMouse`: app source
- `Scripts/create-app-bundle.sh`: bundle builder for `dist/MoveMouse.app`

## Verification

This project is validated with `swift build` on a Command Line Tools-only machine. Full Swift test frameworks were not available in this environment, so the package is currently kept app-only for a cleaner out-of-the-box build.
