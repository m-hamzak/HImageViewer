# Changelog

All notable changes to HImageViewer will be documented in this file.

## [1.1.0] - 2026-04-26

### New Features
- **Per-photo captions** — `PhotoAsset` now accepts an optional `caption: String?` displayed beneath each photo in single-photo mode
- **Share button** — new top-bar share button (configurable via `showShareButton`); tapping shares the current photo or all selected photos via the system share sheet; fires `didTapShareButton(photos:)` on the delegate
- **Context menu** — long-press any photo to Copy, Share, or Save to Photos (configurable via `showContextMenu`, defaults to `true`)
- **Page-change haptic** — optional selection haptic on every swipe, opt-in via `HImageViewerConfiguration(pageChangeHaptic: true)`
- **Landscape layout** — compact top/bottom bars in landscape orientation for maximised image area
- **Zoom to point** — double-tap now zooms into the exact tapped location rather than the image centre
- **Top-bar overflow menu** — when Share, Edit, and Select are all visible, they collapse into a single `···` button matching the iOS overflow pattern

### Improvements
- **Image interpolation** — `.interpolation(.high)` applied to all displayed images; eliminates blur artefacts seen in classic theme
- **Scroll-to-current** — switching from paged view to grid view now scrolls to the currently visible photo
- **iOS 26 Liquid Glass theme** — default glass mode uses `glassEffect` on iOS 26; falls back to `regularMaterial` on iOS 15–25
- **Example app** — 10 example screens covering all features; P2-section heading removed, all screens consolidated under SwiftUI section

### Bug Fixes
- Fixed upload progress overlay not animating when `uploadState` was created outside the viewer
- Fixed classic theme showing blurred images due to missing high-quality interpolation
- Fixed classic theme bottom bar appearing cramped due to inconsistent vertical padding
- Fixed accessibility hint in grid selection mode incorrectly saying "Double-tap" (gesture is single-tap)
- Fixed video player re-creating `AVPlayerItem` unnecessarily on re-appear when URL was unchanged

### Code Quality
- `Array[safe:]` subscript moved to dedicated `Extensions/Array+Safe.swift`
- `.gitignore` added; Xcode `xcuserstate` and `.DS_Store` files removed from tracking
- All P2 phase annotations removed from comments and MARK sections
- 54 new tests added (TopBarOverflowTests, extended haptic, share, caption, zoom, delegate coverage); total 487 tests

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
