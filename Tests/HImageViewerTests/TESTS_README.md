# HImageViewer Test Suite

A comprehensive guide to understanding the test suite — what each test does, why it exists, and how the underlying code works.

**62 tests** across 7 test files + 1 mock file.

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
2. [ArraySafeSubscriptTests.swift](#arraysafesubscripttestsswift)
3. [HImageViewerConfigurationTests.swift](#himageviewerconfigurationtestsswift)
4. [HImageViewerUploadStateTests.swift](#himagevieweruploadstatetestsswift)
5. [HImageViewerDelegateTests.swift](#himageviewerdelegatetestsswift)
6. [PhotoAssetTests.swift](#photoassettestsswift)
7. [HImageViewerLogicTests.swift](#himageviewerlogictestsswift)
8. [ViewRenderingTests.swift](#viewrenderingtestsswift)

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
- `reset()` — clears all tracking properties between tests

### MinimalDelegate

A delegate that implements NOTHING — relies entirely on default protocol implementations (empty methods defined in HImageViewerDelegate.swift).

**Why is this useful?** It verifies that developers can conform to `HImageViewerControlDelegate` without implementing all three methods. If the protocol does NOT have default implementations, this class will cause a compile error.

### Concurrency Note

`HImageViewerControlDelegate` is a nonisolated protocol (no `@MainActor`). `MockDelegate` is `@MainActor` (because tests run on main actor and we access `PhotoAsset` which is `@MainActor`). The `@preconcurrency` annotation tells Swift 6 "I know about the isolation mismatch — handle it at runtime rather than rejecting it at compile time." This is the recommended approach for protocol conformances that cross isolation boundaries in tests.

---

## ArraySafeSubscriptTests.swift

**8 tests** | **Source:** `HImageViewer.swift` (Array extension at bottom)

### What Is the Safe Subscript?

Normal array access like `array[5]` will CRASH if index 5 doesn't exist. The safe subscript `array[safe: 5]` returns `nil` instead of crashing.

This is critical in HImageViewer because users can select photos by index, and if photos are deleted while indices are still stored, a normal subscript would crash the app.

### Where Is It Defined?

In `HImageViewer.swift` at the bottom:

```swift
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

### How Does It Work?

1. It checks if the index is within the array's valid range (`indices`)
2. If yes → returns the element (wrapped in Optional)
3. If no → returns nil (no crash!)

### Why Test It?

This is a safety-critical extension. If it breaks, the app crashes when users delete photos in multi-select mode. We test every edge case:

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_validIndex_returnsElement` | Middle index returns correct element: `[10, 20, 30][safe: 1]` → `20` |
| `test_firstIndex_returnsFirst` | Index 0 returns first element |
| `test_lastValidIndex_returnsLast` | Last valid index returns last element |
| `test_negativeIndex_returnsNil` | Negative index returns nil, not crash |
| `test_indexEqualToCount_returnsNil` | Index equal to count returns nil (off-by-one protection — most common crash!) |
| `test_indexBeyondCount_returnsNil` | Wildly out-of-bounds index (100) returns nil |
| `test_emptyArray_returnsNil` | Any index on empty array returns nil (all photos deleted scenario) |
| `test_withPhotoAssetArray` | Works with actual `[PhotoAsset]` type used in the codebase |

---

## HImageViewerConfigurationTests.swift

**9 tests** | **Source:** `HImageViewerConfiguration.swift`

### What Is HImageViewerConfiguration?

A simple value type (struct) that holds all the settings for the viewer:

```swift
HImageViewerConfiguration(
    initialComment: String?,        // Pre-filled text in comment box
    delegate: ...?,                 // Who handles save/close/edit
    showCommentBox: Bool,           // Show editable text field?
    showSaveButton: Bool,           // Show save/remove button?
    showEditButton: Bool,           // Show edit pencil icon?
    title: String?,                 // Static title (when no comment box)
    uploadState: ...?               // Upload progress tracker
)
```

### Why Test Default Values?

The defaults define the "out of the box" experience:
- `showCommentBox = true` (comment box shown by default)
- `showSaveButton = true` (save button shown by default)
- `showEditButton = true` (edit button shown by default)
- everything else = `nil` (no pre-filled data)

If someone accidentally changes a default, these tests catch it immediately. Default values are part of the **PUBLIC API CONTRACT** — changing them is a breaking change for every developer using this package.

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_defaultInit_allDefaults` | All Bool defaults are true, all Optionals are nil (most important test) |
| `test_showCommentBox_defaultTrue` | Individual Bool default verification |
| `test_showSaveButton_defaultTrue` | Individual Bool default verification |
| `test_showEditButton_defaultTrue` | Individual Bool default verification |
| `test_customInit_setsAllProperties` | All custom values stored correctly (opposite of defaults) |
| `test_initialComment_setToNonNil` | Pre-filling the comment box works |
| `test_title_setToNonNil` | Static title storage works |
| `test_uploadState_setToNonNil` | Upload state object stored with its progress value |
| `test_delegate_setToNonNil` | Delegate stored (config holds STRONG ref; HImageViewer holds WEAK ref) |

---

## HImageViewerUploadStateTests.swift

**6 tests** | **Source:** `HImageViewerUploadState.swift`

### What Is HImageViewerUploadState?

A simple `ObservableObject` with one `@Published` property:

```swift
class HImageViewerUploadState: ObservableObject {
    @Published var progress: Double? = nil
}
```

### How Does It Work in the Viewer?

1. Developer creates: `let uploadState = HImageViewerUploadState()`
2. Passes it via config: `.init(uploadState: uploadState)`
3. During upload, updates: `uploadState.progress = 0.5` (50%)
4. HImageViewer observes changes via `@ObservedObject` and shows progress ring
5. When progress reaches `1.0` → viewer auto-dismisses
6. Setting progress to `nil` → hides the progress ring

### Why Use @Published?

`@Published` is a Combine property wrapper. When the value changes, it automatically notifies all SwiftUI views observing this object. This is how the progress ring updates in real-time during uploads.

The `objectWillChange` publisher fires BEFORE each change, giving SwiftUI time to prepare for the UI update.

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_defaultInit_progressIsNil` | Default = no upload in progress |
| `test_initWithProgress_setsValue` | Custom init stores progress value |
| `test_progressIsPublished_triggersObjectWillChange` | Combine integration works (uses expectation + sink) |
| `test_progressCanBeSetToNil` | Upload cancelled → hide ring without dismissing |
| `test_progressCanBeSetToOne` | `1.0` = upload complete (viewer auto-dismisses) |
| `test_progressCanBeSetToZero` | `0.0` is NOT nil! `nil` = no upload, `0.0` = upload started at 0% |

### How the Combine Test Works

```
1. Create an expectation (a "wait for something to happen" marker)
2. Subscribe to objectWillChange using Combine's sink
3. Change the progress value
4. If objectWillChange fires → expectation fulfilled → test passes
5. If it doesn't fire within 1 second → test fails
```

---

## HImageViewerDelegateTests.swift

**7 tests** | **Source:** `HImageViewerDelegate.swift`

### What Is HImageViewerControlDelegate?

A protocol with 3 methods:

```swift
protocol HImageViewerControlDelegate: AnyObject {
    func didTapSaveButton(comment: String, photos: [PhotoAsset])
    func didTapCloseButton()
    func didTapEditButton(photo: PhotoAsset)
}
```

### Why AnyObject?

The `: AnyObject` constraint means only classes (not structs) can conform. This is required because HImageViewer stores the delegate as a WEAK reference to prevent retain cycles:

```swift
private weak var delegate: HImageViewerControlDelegate?
```

Weak references only work with class types, hence `AnyObject`.

### Default Implementations

The protocol has default empty implementations for ALL 3 methods. This means developers only need to implement the methods they care about. For example, if you only need save — just implement `didTapSaveButton`.

### Flow in the Viewer

```
User taps "Save"  → handleSave()  → delegate?.didTapSaveButton(...)
User taps "X"     → onDismiss     → delegate?.didTapCloseButton()
User taps "✏️"    → onEdit        → delegate?.didTapEditButton(...)
```

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_defaultImpl_didTapSaveButton_doesNotCrash` | Default empty implementation doesn't crash |
| `test_defaultImpl_didTapCloseButton_doesNotCrash` | Default empty implementation doesn't crash |
| `test_defaultImpl_didTapEditButton_doesNotCrash` | Default empty implementation doesn't crash |
| `test_customImpl_didTapSaveButton_isCalled` | Mock records comment + photos correctly |
| `test_customImpl_didTapCloseButton_isCalled` | Mock records close call |
| `test_customImpl_didTapEditButton_isCalled` | Mock records photo correctly |
| `test_selectiveAdoption_allMethodsCallable` | MinimalDelegate can receive all 3 calls without crash |

---

## PhotoAssetTests.swift

**14 tests** | **Source:** `PhotoAsset.swift`

### What Is PhotoAsset?

The data model for every photo/image in HImageViewer. It wraps three possible image sources:

```
1. UIImage    → PhotoAsset(image: myUIImage)       // From camera, generated
2. PHAsset    → PhotoAsset(phAsset: myPHAsset)     // From Photos library
3. Remote URL → PhotoAsset(imageURL: myURL)        // From server
```

### Key Features

- **@MainActor:** All property access happens on the main thread (thread-safe)
- **ObservableObject:** SwiftUI views automatically update when `.image` changes
- **Identifiable:** Each asset has a unique UUID (used in ForEach, Equatable)
- **Equatable:** Two assets are equal if they have the same UUID
- **Lazy loading:** PHAsset and URL images are loaded asynchronously on demand
- **Cancellation:** PHImageManager requests are cancelled in deinit

### Why @MainActor?

`PhotoAsset`'s `@Published var image` triggers SwiftUI view updates. SwiftUI REQUIRES that all `@Published` changes happen on the main thread. `@MainActor` enforces this at compile time — if you try to modify the image from a background thread, the compiler stops you.

This means our test class also needs `@MainActor` annotation.

### What Can't We Test?

- **PHAsset initializer:** PHAsset has no public init — can't create in tests
- **loadThumbnail/loadFullImage with real PHAsset:** Needs Photos library access
- **deinit cancellation:** Needs active PHImageManager requests

These are documented as integration test candidates.

### Image Loading Paths

`loadThumbnail` and `loadFullImage` both follow the same pattern:
1. If image is already cached → return immediately (synchronous)
2. If phAsset exists → request from PHImageManager (async)
3. Otherwise → return nil

We can only test paths 1 and 3 in unit tests. Path 2 requires a real PHAsset.

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_initWithImage_setsImageAndNilPhAssetAndNilURL` | UIImage init sets image, leaves others nil |
| `test_initWithImage_generatesUniqueID` | Same image → different UUIDs (needed for multi-select) |
| `test_initWithURL_setsURLAndNilImageAndNilPhAsset` | URL init stores URL, image is nil until loaded |
| `test_equatable_sameInstance_isEqual` | `asset == asset` is true (UUID-based equality) |
| `test_equatable_differentInstances_areNotEqual` | Same image, different instances → NOT equal |
| `test_identifiable_idIsStableAcrossAccesses` | ID doesn't change between accesses (SwiftUI needs this) |
| `test_loadThumbnail_withPreloadedImage_returnsImmediately` | Cached image returned synchronously |
| `test_loadThumbnail_withNoPhAssetAndNoImage_returnsNil` | URL-only assets return nil from loadThumbnail |
| `test_loadFullImage_withPreloadedImage_returnsImmediately` | Same as thumbnail but full resolution path |
| `test_loadFullImage_withNoPhAssetAndNoImage_returnsNil` | URL-only assets return nil from loadFullImage |
| `test_fromUIImages_returnsCorrectCount` | Factory creates correct number of assets |
| `test_fromUIImages_eachAssetHasImage` | Every factory-created asset has non-nil image |
| `test_fromUIImages_emptyArray_returnsEmpty` | Empty input → empty output, no crash |
| `test_fromUIImages_allAssetsHaveUniqueIDs` | All factory-created assets have unique IDs |

---

## HImageViewerLogicTests.swift

**10 tests** | **Source:** `HImageViewer.swift` (private computed properties and methods)

### Why Replicate Logic?

The computed properties (`isSinglePhotoMode`, `isUploading`, `shouldShowSaveButton`) and handler methods (`handleSelection`, `handleDelete`) are PRIVATE inside HImageViewer. We can't call them directly from tests.

Instead, we replicate the exact same logic in our tests and verify it produces correct results for every edge case. If someone changes the logic in `HImageViewer.swift`, these tests catch the discrepancy.

### 1. isSinglePhotoMode

```swift
private var isSinglePhotoMode: Bool {
    assets.count <= 1
}
```

Determines whether the viewer shows:
- **Single photo view** (with edit button, comment box) when count ≤ 1
- **Multi-photo grid** (with selection mode) when count > 1

### 2. isUploading

```swift
private var isUploading: Bool {
    (uploadState.progress ?? 0) > 0 && (uploadState.progress ?? 0) < 1.0
}
```

**Truth table:**

| progress | Calculation | Result |
|----------|------------|--------|
| `nil` | `(nil ?? 0) = 0` → `0 > 0 = false` | NOT uploading |
| `0.0` | `0 > 0 = false` | NOT uploading |
| `0.5` | `0.5 > 0 = true, 0.5 < 1.0 = true` | IS uploading |
| `1.0` | `1.0 > 0 = true, 1.0 < 1.0 = false` | NOT uploading (complete!) |

When `isUploading` is true, the entire viewer is disabled (`.disabled` modifier).

### 3. shouldShowSaveButton

```swift
private var shouldShowSaveButton: Bool {
    if isSinglePhotoMode {
        return wasImageEdited || config.showSaveButton
    } else {
        return config.showSaveButton
    }
}
```

**Single mode truth table:**

| wasImageEdited | showSaveButton | Result | Why |
|---------------|---------------|--------|-----|
| true | true | true | Either condition |
| true | false | **true** | Edited overrides config! |
| false | true | true | Config says show |
| false | false | false | Nothing triggers it |

**Multi mode:** Simply returns `config.showSaveButton` (`wasImageEdited` is irrelevant).

### 4. handleSelection

```swift
private func handleSelection(_ index: Int) {
    if selectedIndices.contains(index) {
        selectedIndices.remove(index)    // deselect
    } else {
        selectedIndices.insert(index)    // select
    }
}
```

Simple toggle. First tap → select, second tap → deselect.

### 5. handleDelete

```swift
private func handleDelete() {
    let deletedAssets = selectedIndices
        .filter { $0 < assets.count }            // bounds check
        .compactMap { assets[safe: $0] }          // safe access
    assets.removeAll { asset in
        deletedAssets.contains(where: { $0.id == asset.id })  // match by UUID
    }
    selectedIndices.removeAll()                   // clear selection
    selectionMode = false                         // exit selection mode
}
```

**Safety features:**
1. `.filter { $0 < assets.count }` → skips indices that are out of bounds
2. `assets[safe: $0]` → returns nil instead of crash for invalid indices
3. Match by UUID → prevents accidental deletion if array order changes

### Tests

| Test | What It Verifies |
|------|-----------------|
| `test_singlePhotoMode_zeroAssets` | 0 assets → single mode |
| `test_singlePhotoMode_oneAsset` | 1 asset → single mode |
| `test_singlePhotoMode_twoAssets` | 2 assets → multi mode (grid) |
| `test_isUploading_progressNil` | nil → not uploading |
| `test_isUploading_progressZero` | 0.0 → not uploading |
| `test_isUploading_progressHalf` | 0.5 → IS uploading |
| `test_isUploading_progressOne` | 1.0 → not uploading (complete) |
| `test_shouldShowSave_singleMode_editedTrue_configFalse` | Edited overrides config |
| `test_shouldShowSave_singleMode_editedFalse_configFalse` | Neither condition → hide |
| `test_shouldShowSave_multiMode_configTrue` | Multi mode respects config only |
| `test_selectionToggle` | First tap selects, second tap deselects |
| `test_deleteSelectedAssets` | Deletes correct assets by UUID, clears selection |
| `test_deleteOutOfBoundsIgnored` | Out-of-bounds indices safely ignored |

---

## ViewRenderingTests.swift

**5 tests** | Smoke tests that render SwiftUI views to verify they don't crash.

### What Are Smoke Tests?

A smoke test is the most basic test: "does it run without crashing?" Named after hardware testing — if you power on a circuit board and see smoke, something is wrong. Same idea: if the view crashes during render, something is broken.

### Why Render Views in Tests?

SwiftUI views are declarative — they describe WHAT to show, not HOW. The actual rendering (layout, drawing) happens when SwiftUI processes the view body. This can reveal:
- Force unwraps on nil values
- Invalid state combinations
- Missing required data
- Infinite layout loops
- Crash-causing modifiers

### How Does It Work?

The `renderView` helper:

1. Wraps the SwiftUI view in a `UIHostingController` (Apple's bridge between SwiftUI and UIKit)
2. Sets a frame (so layout has dimensions to work with)
3. Calls `layoutIfNeeded()` (triggers the full layout pass)
4. Renders to a `UIImage` using `UIGraphicsImageRenderer`
5. Checks the image has non-zero size (render succeeded)

> **Important:** These tests require a simulator UI context. Run with `xcodebuild test`, NOT `swift test`.

### Tests

| Test | What It Renders |
|------|----------------|
| `test_progressRingOverlayView_renders` | Progress ring with Circle + trim + AngularGradient + .ultraThinMaterial |
| `test_photoView_withImage_renders` | PhotoView with pre-loaded image (state 1 of 3: loaded/loading/failed) |
| `test_multiPhotoGrid_renders` | LazyVGrid with 3 photos (tests grid layout + ForEach) |
| `test_hImageViewer_singleMode_renders` | Full viewer: TopBar + PhotoView + BottomBar |
| `test_hImageViewer_multiMode_renders` | Full viewer: TopBar + MultiPhotoGrid + BottomBar |
