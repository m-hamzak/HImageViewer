# HImageViewer Test Suite

A comprehensive guide to understanding the test suite — what each test does, why it exists, and how the underlying code works.

**533 tests** across 22 test files + 1 mock file.

Run with:
```bash
xcodebuild test \
  -scheme HImageViewer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES
```

> **Note:** These tests require `xcodebuild test`, NOT `swift test`, because some tests use UIKit rendering (UIHostingController, UIGraphicsImageRenderer).

---

## Table of Contents

1. [Mocks/MockDelegate.swift](#mockdelegateswift)
2. [AccessibilityTests.swift](#accessibilitytestsswift)
3. [ArraySafeSubscriptTests.swift](#arraysafesubscripttestsswift)
4. [DragToDismissTests.swift](#dragtodismisstestsswift)
5. [HImageViewerConfigurationTests.swift](#himageviewerconfigurationtestsswift)
6. [HImageViewerDelegateTests.swift](#himageviewerdelegatetestsswift)
7. [HImageViewerLauncherTests.swift](#himageviewerlaunchtestsswift)
8. [HImageViewerLogicTests.swift](#himageviewerlogictestsswift)
9. [HImageViewerUploadStateTests.swift](#himagevieweruploadstatetestsswift)
10. [HapticFeedbackTests.swift](#hapticfeedbacktestsswift)
11. [ImageCacheTests.swift](#imagecachetestsswift)
12. [MediaAssetTests.swift](#mediaassettestsswift)
13. [MultiPhotoGridTests.swift](#multiphotogridtestsswift)
14. [PageIndicatorTests.swift](#pageindicatortestsswift)
15. [PhotoAssetTests.swift](#photoassettestsswift)
16. [ProgressRingOverlayViewTests.swift](#progressringoverlayviewtestsswift)
17. [ReorderTests.swift](#reordertestsswift)
18. [SwipePagingTests.swift](#swipeagingtestsswift)
19. [TopBarCancelSelectionTests.swift](#topbarcancelselectiontestsswift)
20. [TopBarOverflowTests.swift](#topbaroverflowetestsswift)
21. [VideoPlayerViewTests.swift](#videoplayerviewtestsswift)
22. [ViewRenderingTests.swift](#viewrenderingtestsswift)
23. [ZoomableImageViewTests.swift](#zoomableimagetestsswift)

---

## MockDelegate.swift

**Location:** `Tests/HImageViewerTests/Mocks/MockDelegate.swift`

### Why Do We Need Mocks?

In unit tests, we don't want to use real view controllers or upload managers. Instead, we create "mock" objects that RECORD what methods were called and with what arguments. This lets us verify that HImageViewer calls the right delegate methods at the right time, without needing any real UI or backend.

### How Mocks Work

1. The mock implements the same protocol as the real delegate
2. Instead of doing real work, it stores the call data in properties
3. In our tests, we check those properties to verify behavior

```swift
let mock = MockDelegate()
someView.delegate = mock
someView.tapSaveButton()              // triggers didTapSaveButton
XCTAssertTrue(mock.didTapSaveCalled)  // verify it was called
```

### MockDelegate

A fully-instrumented mock that records every delegate call. Use it when you need to VERIFY that specific delegate methods were called with the correct parameters.

**Tracking properties:**
- `didTapSaveCalled` / `lastSaveComment` / `lastSavePhotos` — records save button calls
- `didTapCloseCalled` — records close button calls
- `didTapEditCalled` / `lastEditPhoto` — records edit button calls
- `didTapShareCalled` / `lastSharePhotos` — records share button calls
- `didDeleteCalled` / `lastDeletedAssets` — records deletion calls
- `didChangePageCalled` / `lastChangedPageIndex` — records page-change calls
- `reset()` — clears all tracking properties between tests

### MinimalDelegate

A delegate that implements NOTHING — relies entirely on default protocol implementations (empty methods defined in HImageViewerDelegate.swift).

**Why is this useful?** It verifies that developers can conform to `HImageViewerControlDelegate` without implementing all six methods. If the protocol does NOT have default implementations, this class will cause a compile error.

### Concurrency Note

`HImageViewerControlDelegate` is a nonisolated protocol (no `@MainActor`). `MockDelegate` is `@MainActor` (because tests run on main actor and we access `PhotoAsset` which is `@MainActor`). The `@preconcurrency` annotation tells Swift 6 "I know about the isolation mismatch — handle it at runtime rather than rejecting it at compile time." This is the recommended approach for protocol conformances that cross isolation boundaries in tests.

---

## AccessibilityTests.swift

**27 tests** | **Source:** Multiple view files

Tests every user-facing accessibility string exposed by HImageViewer — labels, hints, and VoiceOver values. Split into five areas:

| Area | What Is Tested |
|------|---------------|
| `PageDotsView.accessibilityLabel` | "Page N of M" format for VoiceOver |
| `ProgressRingOverlayView.progressAccessibilityLabel` | "Uploading, N percent" with and without a title |
| `MultiPhotoGrid.tileLabel(for:at:)` | "Photo N" / "Video N" 1-based labels |
| `CircleButton` accessibility properties | `.accessibilityLabel` and `.accessibilityHint` stored correctly |
| `TopBarConfig.accessibilityPageLabel` | Propagation to the TopBar view |
| `BottomBarConfig` action label | "Save photo" vs "Remove selected items" derivation |

**Why test accessibility strings?** VoiceOver reads these labels to blind users. A wrong label (e.g., `"Page 0 of 5"` instead of `"Page 1 of 5"`) makes the app functionally broken for them.

---

## ArraySafeSubscriptTests.swift

**8 tests** | **Source:** `Array+SafeSubscript.swift`

### What Is the Safe Subscript?

Normal array access like `array[5]` will CRASH if index 5 doesn't exist. The safe subscript `array[safe: 5]` returns `nil` instead of crashing.

This is critical in HImageViewer because users can select photos by index, and if photos are deleted while indices are still stored, a normal subscript would crash the app.

### Where Is It Defined?

```swift
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_validIndex_returnsElement` | Middle index returns correct element: `[10, 20, 30][safe: 1]` → `20` |
| `test_firstIndex_returnsFirst` | Index 0 returns first element |
| `test_lastValidIndex_returnsLast` | Last valid index returns last element |
| `test_negativeIndex_returnsNil` | Negative index returns nil, not crash |
| `test_indexEqualToCount_returnsNil` | Index equal to count returns nil (off-by-one protection) |
| `test_indexBeyondCount_returnsNil` | Wildly out-of-bounds index (100) returns nil |
| `test_emptyArray_returnsNil` | Any index on empty array returns nil (all photos deleted scenario) |
| `test_withPhotoAssetArray` | Works with actual `[PhotoAsset]` type used in the codebase |

---

## DragToDismissTests.swift

**43 tests** | **Source:** `HImageViewerViewModel.swift`, `HImageViewer.swift`

Tests the drag-to-dismiss gesture logic: progress calculation, threshold detection, and direction filtering. All tested against pure functions so no gesture recognizer simulation is needed.

### Three areas covered

**1. `dragProgress` calculation**
Maps `dragOffset` → `0.0...1.0`. Used to fade the viewer as the user drags down.

| Scenario | Expected |
|----------|---------|
| Zero offset | `0.0` |
| At threshold | `1.0` |
| Half threshold | `0.5` |
| Beyond threshold | clamped to `1.0` |
| Negative offset (upward drag) | `0.0` |

**2. `shouldDismiss` threshold logic**
Returns `true` when either the raw translation or the predicted end translation exceeds the dismiss threshold (120 pt). This lets a fast flick dismiss the viewer even if the finger hasn't moved far.

**3. Direction filter**
Only downward drags (height > 0, height > |width| × 1.5) qualify. Horizontal swipes pass through to the pager unimpeded.

Additional tests cover edge cases: progress clamping, threshold boundary exactness, selection mode bypassing the gesture, and upload-in-progress bypassing the gesture.

---

## HImageViewerConfigurationTests.swift

**36 tests** | **Source:** `HImageViewerConfiguration.swift`

### What Is HImageViewerConfiguration?

A value type (struct) that holds all the settings for the viewer. Every parameter has a sensible default so `HImageViewerConfiguration()` with no arguments works out of the box.

### Why Test Default Values?

The defaults define the "out of the box" experience. If someone accidentally changes a default, these tests catch it immediately. Default values are part of the **PUBLIC API CONTRACT** — changing them is a breaking change for every developer using this package.

### Key defaults verified

| Parameter | Default |
|-----------|---------|
| `showCommentBox` | `true` |
| `showSaveButton` | `true` |
| `showEditButton` | `true` |
| `showShareButton` | `true` |
| `showContextMenu` | `true` |
| `pageChangeHaptic` | `false` |
| `tintColor` | `nil` (Glass mode) |
| `backgroundColor` | `Color(.systemBackground)` |
| `initialComment`, `title`, `uploadState`, `delegate`, `placeholderView`, `errorView` | `nil` |

Tests also verify custom values round-trip correctly, `isGlassMode` derives correctly from `tintColor`, and `resolvedTintColor` falls back to `.accentColor` when nil.

---

## HImageViewerDelegateTests.swift

**25 tests** | **Source:** `HImageViewerDelegate.swift`

### What Is HImageViewerControlDelegate?

A protocol with six methods (all with default no-op implementations):

```swift
protocol HImageViewerControlDelegate: AnyObject {
    func didTapSaveButton(comment: String, photos: [PhotoAsset])
    func didTapCloseButton()
    func didTapEditButton(photo: PhotoAsset)
    func didDeleteMediaAssets(_ assets: [MediaAsset])
    func didChangePage(to index: Int)
    func didTapShareButton(photos: [PhotoAsset])
}
```

### Why AnyObject?

The `: AnyObject` constraint means only classes (not structs) can conform. This is required because HImageViewer stores the delegate as a WEAK reference to prevent retain cycles. Weak references only work with class types.

### Tests

Tests verify:
- All six default implementations compile and don't crash
- `MockDelegate` records arguments correctly for each method
- `MinimalDelegate` (implements nothing) can receive all six calls without compile error
- The `didTapShareButton` callback receives the correct `[PhotoAsset]` array
- `didChangePage` receives the correct zero-based index
- `didDeleteMediaAssets` receives the correct removed assets

---

## HImageViewerLauncherTests.swift

**9 tests** | **Source:** `HImageViewerLauncher.swift`

Tests for the UIKit entry point. Since `HImageViewerLauncher` is a static API that requires a live `UIViewController`, these tests use a `UIWindow` with a root controller to call `present` and `push` in a headless simulator context.

| Test | What It Verifies |
|------|-----------------|
| `test_present_doesNotCrash` | `HImageViewerLauncher.present` completes without crash |
| `test_push_doesNotCrash` | `HImageViewerLauncher.push` completes without crash |
| `test_present_withConfiguration_doesNotCrash` | Custom config passes through without crash |
| `test_present_withOnChange_doesNotCrash` | `onChange` closure parameter accepted without crash |
| `test_present_withInitialIndex_doesNotCrash` | `initialIndex` accepted without crash |
| `test_present_emptyMediaAssets_doesNotCrash` | Empty array doesn't crash |
| `test_push_withConfiguration_doesNotCrash` | Push with custom config doesn't crash |
| `test_present_withDelegate_doesNotCrash` | Delegate passed through without crash |
| `test_present_withUploadState_doesNotCrash` | Upload state passed through without crash |

---

## HImageViewerLogicTests.swift

**68 tests** | **Source:** `HImageViewerViewModel.swift`

The most comprehensive file — exercises all ViewModel business logic via direct method calls.

### Areas covered

**1. isUploading**

Truth table:

| progress | Result |
|----------|--------|
| `nil` | NOT uploading |
| `0.0` | NOT uploading |
| `0.5` | IS uploading |
| `1.0` | NOT uploading (complete) |

**2. shouldShowSaveButton**

Depends on `config.showSaveButton` only (single photo mode no longer has a separate `wasImageEdited` — behavior maps cleanly to config).

**3. handleSelection (toggle)**

First tap selects, second tap deselects. Multiple indices can be selected simultaneously.

**4. handleDelete**

- Deletes by UUID so order changes don't cause wrong deletions
- Clears `selectedIndices` and exits `selectionMode` after delete
- Guard: empty selection → no-op
- Notifies delegate with the deleted assets

**5. pageCounterText / accessibilityPageCounterText**

| Scenario | pageCounterText | accessibilityPageCounterText |
|----------|----------------|------------------------------|
| 1 item | `nil` | `nil` |
| 2 items, index 0 | `"1 / 2"` | `"Page 1 of 2"` |
| 5 items, index 2 | `"3 / 5"` | `"Page 3 of 5"` |
| Selection mode | `nil` | `nil` |

**6. dragProgress**

Maps 0…threshold to 0…1.0, clamped.

**7. currentPhotoAsset**

Returns `PhotoAsset?` for the current index (nil for videos, nil when out of bounds).

**8. reorderItems, cancelSelection**

Covered in more depth in their dedicated test files; also exercised here as part of ViewModel integration.

---

## HImageViewerUploadStateTests.swift

**13 tests** | **Source:** `HImageViewerUploadState.swift`

### What Is HImageViewerUploadState?

```swift
class HImageViewerUploadState: ObservableObject {
    @Published var progress: Double? = nil
}
```

### How Does It Work in the Viewer?

1. Developer creates: `let uploadState = HImageViewerUploadState()`
2. Passes it via config: `.init(uploadState: uploadState)`
3. During upload, updates: `uploadState.progress = 0.5` (50%)
4. HImageViewer observes changes via Combine and shows progress ring
5. When progress reaches `1.0` → viewer auto-dismisses
6. Setting progress to `nil` → hides the progress ring

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_defaultInit_progressIsNil` | Default = no upload in progress |
| `test_initWithProgress_setsValue` | Custom init stores progress value |
| `test_progressIsPublished_triggersObjectWillChange` | Combine integration works |
| `test_progressCanBeSetToNil` | Upload cancelled → hide ring without dismissing |
| `test_progressCanBeSetToOne` | `1.0` = upload complete |
| `test_progressCanBeSetToZero` | `0.0` is NOT nil: upload started at 0% |
| + 7 more | Range clamping, publish frequency, objectWillChange count |

---

## HapticFeedbackTests.swift

**23 tests** | **Source:** `HImageViewerViewModel.swift`, `HapticFeedbackProvider.swift`

### Design

A `MockHapticFeedbackProvider` spy is injected into the ViewModel at construction time. The spy records every `impact(_:)` and `selection()` call so tests can assert haptic style and call count without touching real hardware.

### Per-action haptic contract

| Action | Expected haptic |
|--------|----------------|
| `handleSelection` (select or deselect) | `.impact(.medium)` |
| `cancelSelection` | `.impact(.light)` |
| `handleDelete` (with items selected) | `.impact(.heavy)` |
| `handleSave` | `.impact(.medium)` |
| `handleDelete` (empty selection) | none — guard exits early |
| Page swipe (`pageChangeHaptic: true`) | `.selection()` |
| Page swipe (`pageChangeHaptic: false`) | none |
| Setting `currentIndex` to same value | none |

### Real provider smoke tests

Six tests call every impact style and `selection()` on the real `HapticFeedbackProvider`. These verify that `.soft` and `.rigid` (which previously fell through to `@unknown default` and allocated a new generator each call) are handled by pre-warmed instances.

---

## ImageCacheTests.swift

**16 tests** | **Source:** `ImageCache.swift`

### What Is ImageCache?

A thin wrapper around `NSCache<NSString, UIImage>` providing URL-keyed image storage with LRU eviction.

```swift
ImageCache.shared[url] = image   // store
let img = ImageCache.shared[url] // retrieve (nil if not cached)
ImageCache.shared[url] = nil     // remove
ImageCache.shared.removeAll()    // clear everything
```

### Key behaviors tested

- Store/retrieve round-trip
- Unknown URL returns `nil`
- Multiple URLs cached independently
- Setting `nil` removes the entry
- `removeAll()` clears everything and is idempotent
- `shared` is a singleton (same reference)
- Removing one entry doesn't affect others

### Cost correctness

`NSCache` uses a `cost` parameter for LRU eviction. Two critical tests:

1. **Zero-dimension image**: `max(1, cost)` ensures NSCache never receives a cost of `0`, which would make the image "free" and bypass eviction entirely.
2. **Retina scale**: cost = `width × scale × height × scale × 4`. A 2× retina image costs exactly 4× the equivalent 1× image — matching the actual byte size in memory.

---

## MediaAssetTests.swift

**33 tests** | **Source:** `MediaAsset.swift`

### What Is MediaAsset?

The unified sum type for photos and videos:

```swift
enum MediaAsset {
    case photo(PhotoAsset)
    case video(URL)
}
```

### Tests cover

- `kind` switch correctness for `.photo` and `.video`
- `isPhoto` / `isVideo` computed properties
- `photoAsset` returns `PhotoAsset?` (nil for videos)
- `videoURL` returns `URL?` (nil for photos)
- `id` property stability and uniqueness
- `from(uiImages:)` and `from(videoURLs:)` batch helpers
- Mixed-type equality (photo ≠ video even with same content)
- Identifiable conformance in ForEach contexts
- Batch helpers produce correct counts and non-overlapping IDs

---

## MultiPhotoGridTests.swift

**9 tests** | **Source:** `MultiPhotoGrid.swift`

### What Is `tileLabel(for:at:)`?

A static helper that produces the VoiceOver label for each grid tile:

```
Photo at index 0  →  "Photo 1"
Video at index 2  →  "Video 3"
```

The label is **1-based** (human-readable) even though the index is **0-based**.

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_tileLabel_photo_atIndexZero` | "Photo 1" |
| `test_tileLabel_photo_atIndexOne` | "Photo 2" |
| `test_tileLabel_photo_atLargeIndex` | "Photo 10" (index 9) |
| `test_tileLabel_video_atIndexZero` | "Video 1" |
| `test_tileLabel_video_atIndexTwo` | "Video 3" |
| `test_tileLabel_photo_labelContainsHumanReadableNumber` | Contains "5", NOT "4" for index 4 |
| `test_tileLabel_video_labelContainsHumanReadableNumber` | Contains "1" for index 0 |
| `test_tileLabel_photo_prefixIsPhoto` | hasPrefix("Photo") |
| `test_tileLabel_video_prefixIsVideo` | hasPrefix("Video") |

---

## PageIndicatorTests.swift

**25 tests** | **Source:** `PageDotsView.swift`, `HImageViewerViewModel.swift`

### Two components tested

**1. `pageCounterText` string formatting** (pure logic)

| Scenario | Expected |
|----------|---------|
| 0 assets | `nil` |
| 1 asset | `nil` |
| 2+ assets, index 0 | `"1 / N"` |
| 2+ assets in selection mode | `nil` |
| 100 assets, index 99 | `"100 / 100"` |

**2. `PageDotsView.shouldShow`**

Dots are shown only when `count` is in `2...PageDotsView.maxDots` (max = 8). Above 8 items the dots are suppressed to avoid a cluttered row of tiny circles.

| count | shouldShow |
|-------|-----------|
| 0 | false |
| 1 | false |
| 2–8 | true |
| 9+ | false |

Also includes four rendering smoke tests (TopBar with/without counter, PageDotsView with/without content).

---

## PhotoAssetTests.swift

**40 tests** | **Source:** `PhotoAsset.swift`

### What Is PhotoAsset?

The data model for every photo in HImageViewer, wrapping three possible image sources:

```
1. UIImage    → PhotoAsset(image: myUIImage)
2. PHAsset    → PhotoAsset(phAsset: myPHAsset)
3. Remote URL → PhotoAsset(imageURL: myURL)
```

### Key features

- `@MainActor` — all property access on the main thread
- `ObservableObject` — SwiftUI views update when `.image` changes
- `Identifiable` — stable UUID
- `Equatable` — UUID-based equality
- `@Published var loadError: Error?` — set when a URL load fails, cleared when a new load starts

### Tests cover

- UIImage init stores image, leaves `phAsset` and `imageURL` nil
- URL init stores URL, image is nil until loaded
- Same-image assets get different UUIDs (multi-select safety)
- UUID doesn't change when `image` is replaced or cleared
- `loadThumbnail` / `loadFullImage` with pre-loaded image → synchronous completion
- Cache hit → synchronous completion and sets `asset.image`
- Cache miss → no synchronous completion
- `cancelPendingLoad` is always safe (before load, during load, after cancel, repeated calls)
- `from(uiImages:)` factory: count, non-nil images, unique IDs
- `loadError` is nil initially and for UIImage-backed assets
- `loadError` is set after a network failure (localhost:1 URL)
- `loadError` is cleared when a new load starts

---

## ProgressRingOverlayViewTests.swift

**12 tests** | **Source:** `ProgressRingOverlayView.swift`

### What Is `progressAccessibilityLabel`?

The VoiceOver label for the upload progress ring:

```
ProgressRingOverlayView(progress: 0.5, title: "Uploading")
→ "Uploading, 50 percent"

ProgressRingOverlayView(progress: 0.5)
→ "Upload progress, 50 percent"
```

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_label_noTitle_zeroPercent` | Default prefix + "0 percent" |
| `test_label_noTitle_fiftyPercent` | Default prefix + "50 percent" |
| `test_label_noTitle_hundredPercent` | Default prefix + "100 percent" |
| `test_label_noTitle_truncatesDecimal` | `Int(0.476 * 100)` = 47 (truncation, not rounding) |
| `test_label_withTitle_zeroPercent` | Custom title + "0 percent" |
| `test_label_withTitle_fiftyPercent` | Custom title + "50 percent" |
| `test_label_withCustomTitle_usesProvidedTitle` | "Saving, 30 percent" |
| `test_label_nilTitle_usesDefaultPrefix` | hasPrefix("Upload progress,") |
| `test_label_nonNilTitle_doesNotContainDefaultPrefix` | provided title replaces default entirely |
| `test_label_alwaysContainsPercentSuffix` | hasSuffix("percent") for 0, 0.33, 0.66, 1.0 |
| + 2 more | `test_label_withTitle_nearComplete`, `test_progressLabel_customTitle_quarterWay` |

---

## ReorderTests.swift

**14 tests** | **Source:** `HImageViewerViewModel.reorderItems(from:to:)`

### What Does `reorderItems` Do?

Moves the item at `fromIndex` to `toIndex` using `Array.move(fromOffsets:toOffset:)`. It also clears `selectedIndices` to prevent stale index references pointing to the wrong items after the move.

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_reorderItems_movesForward` | [A,B,C] from:0 to:2 → [B,C,A] |
| `test_reorderItems_adjacentForward` | [A,B,C] from:0 to:1 → [B,A,C] |
| `test_reorderItems_movesBackward` | [A,B,C] from:2 to:0 → [C,A,B] |
| `test_reorderItems_adjacentBackward` | [A,B,C] from:1 to:0 → [B,A,C] |
| `test_reorderItems_twoItems_swap` | [A,B] from:0 to:1 → [B,A] |
| `test_reorderItems_sameIndex_noChange` | Same index = no-op |
| `test_reorderItems_fromOutOfBounds_noChange` | OOB from = no-op |
| `test_reorderItems_toOutOfBounds_noChange` | OOB to = no-op |
| `test_reorderItems_negativeFrom_noChange` | Negative from = no-op |
| `test_reorderItems_clearsSelectedIndices` | Selection cleared after move |
| `test_reorderItems_sameIndex_doesNotClearSelection` | No-op does NOT clear selection |
| `test_reorderItems_preservesItemCount` | Count unchanged after move |
| `test_reorderItems_preservesAllIDs` | All UUIDs still present |
| `test_reorderItems_withVideoItem_movesCorrectly` | Photo+video mix moves correctly |

---

## SwipePagingTests.swift

**20 tests** | **Source:** `HImageViewerViewModel.swift`

Tests the paging state machine: index clamping on init, bounds after deletion, and the `currentPhotoAsset` / `currentVideoURL` derived properties.

### Key invariants

- `currentIndex` is always clamped to `0...(count-1)` — never out of bounds
- `initialIndex` beyond count is silently clamped (no crash)
- After deletion the index is adjusted to point to a valid item
- `currentPhotoAsset` returns `nil` for videos and out-of-bounds indices
- Swipe does not fire `selection()` haptic when `pageChangeHaptic` is `false`
- `didChangePage` is not called when `currentIndex` is set to the same value

---

## TopBarCancelSelectionTests.swift

**11 tests** | **Source:** `HImageViewerViewModel.cancelSelection()`

Tests the state reset triggered by the Cancel button in multi-select mode.

### Contract

`cancelSelection()` must:
1. Set `selectionMode = false`
2. Clear all entries from `selectedIndices`
3. Fire `.impact(.light)` haptic

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_cancelSelection_setsModeToFalse` | `selectionMode` becomes `false` |
| `test_cancelSelection_clearsSelectedIndices` | `selectedIndices` is empty |
| `test_cancelSelection_withNoSelection_stillClearsMode` | Works even when nothing is selected |
| `test_cancelSelection_triggersLightHaptic` | Haptic style = `.light` |
| + 7 more | Multiple selections cleared, idempotent second cancel, etc. |

---

## TopBarOverflowTests.swift

**28 tests** | **Source:** `TopBar.swift`

### The Overflow Rule

When `visibleCount` (Share + Edit + Select buttons that are enabled) is ≥ 2, TopBar collapses them into a single `…` overflow menu. When exactly 1 is visible it is shown inline. When 0 are visible the trailing slot is empty.

### Tests

| Group | Count | What is verified |
|-------|-------|-----------------|
| Zero visible | 2 | `visibleCount == 0`, no overflow |
| One visible | 6 | Each of the three buttons alone, no overflow |
| Two visible | 6 | Every pair triggers overflow |
| All three visible | 2 | `visibleCount == 3`, overflow |
| Edge / regression | 12 | Selection mode suppresses buttons, overflow title text, boundary values |

The `shouldOverflow` function is the exact same expression used inside `TopBar`'s body — testing it separately guards against future refactors changing the collapse rule unintentionally.

---

## VideoPlayerViewTests.swift

**16 tests** | **Source:** `VideoPlayerView.swift`, `PlayerHolder`

### What Is PlayerHolder?

The AVFoundation host object inside `VideoPlayerView`:

```swift
final class PlayerHolder: ObservableObject {
    let player = AVPlayer()
    @Published private(set) var itemStatus: AVPlayerItem.Status = .unknown
    // ...
}
```

It manages `AVAudioSession` setup, item replacement, and Combine-based status observation.

### Tests

| Group | Tests | What is verified |
|-------|-------|-----------------|
| Aspect ratio | 3 | Non-video URL → nil, missing file → nil, positive when non-nil |
| Initial state | 2 | `itemStatus == .unknown`, `player.currentItem == nil` |
| Audio session | 2 | Category = `.playback`, mode = `.moviePlayback` |
| `setItem` | 4 | Item installed, status reset to `.unknown`, second call replaces first |
| `clearItem` | 3 | Item removed, status reset, safe when nothing set |
| Observation cancellation | 2 | Replacing item cancels previous Combine pipeline; clearing cancels it too |

---

## ViewRenderingTests.swift

**13 tests** | Smoke tests that render SwiftUI views to verify they don't crash.

### What Are Smoke Tests?

A smoke test is the most basic test: "does it run without crashing?" If the view crashes during render, something is broken.

### How Does It Work?

The `renderView` helper:

1. Wraps the SwiftUI view in a `UIHostingController`
2. Sets a frame so layout has dimensions to work with
3. Calls `layoutIfNeeded()` (triggers the full layout pass)
4. Renders to a `UIImage` using `UIGraphicsImageRenderer`
5. Checks the image has non-zero size (render succeeded)

### Tests

| Test | What It Renders |
|------|----------------|
| `test_progressRingOverlayView_renders` | Progress ring with Circle + trim + AngularGradient + .ultraThinMaterial |
| `test_photoView_withImage_renders` | PhotoView with pre-loaded image |
| `test_multiPhotoGrid_renders` | LazyVGrid with 3 photos |
| `test_hImageViewer_singleMode_renders` | Full viewer: TopBar + PhotoView + BottomBar |
| `test_hImageViewer_multiMode_renders` | Full viewer: TopBar + MultiPhotoGrid + BottomBar |
| + 8 more | Bottom bar renders, top bar in selection mode, ZoomableImageView, VideoPlayerView, mixed media, remote URL placeholder |

---

## ZoomableImageViewTests.swift

**44 tests** | **Source:** `ZoomableImageView.swift`

### What Is Tested?

The zoom engine's pure functions — no gesture simulation required.

**1. `zoomClamp(_:min:max:)`**

Clamps a scale factor to `[minScale, maxScale]`.

| Input | Result |
|-------|--------|
| Below min | `ZoomDefaults.minScale` |
| Above max | `ZoomDefaults.maxScale` |
| In range | unchanged |
| Custom min/max | correctly clamped to the custom range |

**2. `zoomToggle(current:)`**

Double-tap target: if at min scale → jump to `doubleTapScale`; if zoomed in → return to min.

**3. `zoomOffset(for:in:scale:)`**

Given a tap point, container bounds, and scale, computes the scroll offset so the tapped point stays under the finger after zoom. Tests verify edge cases: zero scale guard, out-of-bounds tap points, portrait vs landscape containers.

**4. Rendering smoke test**

`ZoomableImageView` renders without crash for a pre-loaded `UIImage`.

**5. ZoomDefaults constants**

Verifies the compile-time constants (`minScale = 1.0`, `maxScale = 5.0`, `doubleTapScale = 2.5`) haven't drifted.
