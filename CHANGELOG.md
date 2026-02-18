# Changelog

All notable changes to HImageViewer will be documented in this file.

## [1.0.2] - 2026-02-18

###  Code Quality & Documentation
- Added comprehensive DocC documentation throughout the codebase
- Renamed `Protocol.swift` to `HImageViewerDelegate.swift` for better clarity
- Added MARK comments to all files for improved code organization
- Added default protocol implementations for flexible delegate adoption
- Made internal properties `private` for better encapsulation
- Removed all commented code for cleaner codebase

###  Developer Experience
- Added detailed usage examples in DocC comments
- Created `HImageViewerLauncher` documentation for UIKit integration
- Documented upload progress architecture and usage patterns
- Added important notes about delegate retain cycles
- Improved code discoverability with better file naming

###  API Improvements
- Protocol methods now have default empty implementations
- More flexible delegate adoption pattern
- Better separation of concerns in configuration
- Clearer API surface with improved naming

## [1.0.1] - 2025-02-17

###  Bug Fixes
- Fixed force unwrap crash when edit button tapped with empty assets array
- Fixed index out of bounds crash in multi-photo delete operation
- Fixed `initialComment` configuration parameter not being used
- Fixed type inference conflict in `onChange` modifier with `@MainActor`

###  Thread Safety
- Added `@MainActor` annotation to `PhotoAsset` for thread-safe UI updates
- Fixed PHImageManager completion handlers to execute on main thread
- Added `nonisolated` to Equatable conformance to prevent actor isolation warnings
- All `@Published` property updates now guaranteed on main thread

###  Memory Management
- Added request cancellation for PHImageManager image loading
- Implemented proper cleanup in `PhotoAsset.deinit` to cancel pending requests
- Replaced synchronous `Data(contentsOf:)` with async URLSession for remote images
- Added task cancellation when `PhotoView` disappears during image loading
- Added AVPlayer resource cleanup in `VideoPlayerView` on disappear and deinit
- Weak self references in closures prevent retain cycles

###  Improvements
- Auto-dismiss viewer when all assets are deleted in multi-photo mode
- Removed unused Configuration struct to reduce API confusion
- Removed unused state variables for cleaner codebase
- Better async/await implementation for iOS 15+ compatibility

###  Technical Details
- Safe array subscripting prevents index out of bounds crashes
- Proper resource cleanup prevents memory leaks
- Thread-safe property access throughout the library
- Modern async/await patterns for network operations

## [1.0.0] - 2025-02-16

###  Initial Release
- Single & multi-photo viewing modes
- Video playback support with AVPlayer
- Optional editable comment box and static title
- Configurable Save button
- Selection mode for multi-photo delete
- Delegates for UIKit integration
- Full iOS 15+ support
- SwiftUI + UIKit compatibility
- Orientation support (portrait & landscape)
