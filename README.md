# MoveMouse for macOS

MoveMouse is a native SwiftUI menu bar app for macOS that keeps your Mac awake without moving the pointer. It runs in the menu bar, uses macOS power assertions to prevent idle sleep, and can limit activity to a schedule.

## What it does

- Runs as a lightweight menu bar utility.
- Prevents display sleep and/or system idle sleep while active.
- Lets you limit activity to a daily time window, including overnight schedules.
- Avoids Accessibility permission prompts and synthetic cursor movement.

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

## Project layout

- `Sources/MoveMouse`: app source
- `Scripts/create-app-bundle.sh`: bundle builder for `dist/MoveMouse.app`

## Verification

This project is validated with `swift build` on a Command Line Tools-only machine. Full Swift test frameworks were not available in this environment, so the package is currently kept app-only for a cleaner out-of-the-box build.

## App Store direction

This version is designed around App Store-safer behavior: no Accessibility trust flow and no synthetic mouse events. For actual App Store submission, the next step is creating a signed Xcode app target with App Sandbox enabled and shipping this keep-awake behavior as the primary feature.
