# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zavala is a dedicated outliner application for macOS, iPadOS, and iOS. It allows users to create hierarchical outlines for organizing thoughts, tasks, and information with CloudKit sync across devices.

## Architecture

This is an iOS/macOS app built with:
- **Swift/UIKit** for the main application
- **Xcode project** structure with multiple targets
- **VinOutlineKit** - Core Swift package containing the outline data model, commands, and business logic
- **CloudKit integration** for cross-device synchronization
- **App Intents** for Shortcuts integration
- **Spotlight integration** via SpotlightIndexExtension

### Key Components

- **VinOutlineKit/**: Core Swift package with outline data structures, commands, and CloudKit sync
- **Zavala/**: Main iOS/macOS app with UI controllers and views
- **AppKitPlugin/**: macOS-specific functionality
- **SpotlightIndexExtension/**: Spotlight search integration
- **Shortcuts/**: Collection of example Shortcuts integrations

### Data Model

The core entities are:
- **Account**: Container for outlines (Local, CloudKit)
- **Outline**: Document containing hierarchical rows
- **Row**: Individual outline item with topic, note, and completion state
- **Tag**: Labels for organizing outlines

## Development Commands

### Building
```bash
# Build the project (use Xcode)
xcodebuild -project Zavala.xcodeproj -scheme Zavala build

# Archive and install (via build script)
cd tools && ./build.sh
```

### Testing
```bash
# Run tests for VinOutlineKit
cd VinOutlineKit
swift test

# Run tests via Xcode
xcodebuild -project Zavala.xcodeproj -scheme Zavala test -testPlan Zavala
```

### Xcode Project Structure
- Main app target: **Zavala**
- Package dependency: **VinOutlineKit** (local Swift package)
- Extensions: **SpotlightIndexExtension**, **AppKitPlugin**
- Test plan: `Zavala.xctestplan` (includes VinOutlineKitTests)

## Code Conventions

- Swift 6.0 with strict concurrency enabled
- Follows Apple's UI patterns (UIKit, SwiftUI for settings)
- Command pattern for outline operations (see `VinOutlineKit/Commands/`)
- Delegate patterns for UI coordination
- CloudKit for data persistence and sync

## Key Directories

- `VinOutlineKit/Sources/VinOutlineKit/`: Core data model and business logic
- `Zavala/Editor/`: Outline editing interface
- `Zavala/Collections/`: Outline collection views
- `Zavala/Documents/`: Document management
- `Zavala/Settings/`: App preferences and configuration
- `Zavala/AppIntents/`: Shortcuts integration

## Important Notes

- The project uses a local Swift package (VinOutlineKit) for core functionality
- CloudKit integration requires proper entitlements and Apple Developer account setup
- App Store distribution requires proper code signing and provisioning profiles
- Localization strings are in `.xcstrings` format