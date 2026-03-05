# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRAVEL GUIDED TOUR is a multi-platform SwiftUI app targeting iOS, macOS, and visionOS. It is currently a starter project scaffolded with Xcode 26.3.

## Build & Run

```bash
# Build for macOS
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build

# Build for iOS Simulator
xcodebuild -scheme "TRAVEL GUIDED TOUR" -destination "generic/platform=iOS Simulator" build
```

No test targets are configured yet.

## Architecture

- **Entry point:** `TRAVEL GUIDED TOUR/TRAVEL_GUIDED_TOURApp.swift` — `@main` app struct with a single `WindowGroup` containing `ContentView`
- **Main view:** `TRAVEL GUIDED TOUR/ContentView.swift` — root SwiftUI view
- **Assets:** `TRAVEL GUIDED TOUR/Assets.xcassets/` — app icons and accent color

## Build Configuration

- **Bundle ID:** `com.ehky.TRAVEL-GUIDED-TOUR`
- **Swift Language Mode:** Swift 5.0
- **Deployment Targets:** iOS 26.2, macOS 26.2, xROS 26.2
- **Device Families:** iPhone, iPad, Apple Vision
- **App Sandbox:** Enabled (read-only file access)
- **Code Signing:** Automatic
