# HImageViewer

A lightweight, plug-and-play SwiftUI image and video viewer for iOS.  
Drop it into any SwiftUI **or** UIKit / Storyboard app with a single line of code.

[![CI](https://github.com/m-hamzak/HImageViewer/actions/workflows/ci.yml/badge.svg)](https://github.com/m-hamzak/HImageViewer/actions/workflows/ci.yml)
![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen)
![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Features

- **Paged gallery** — swipe horizontally through photos and videos
- **Pinch-to-zoom & double-tap zoom** on photos (zoom-to-point precision on double-tap)
- **Native video playback** via AVKit with full transport controls and error-recovery overlay
- **Multi-select mode** — tap Select to enter a checkmark grid
- **Drag-to-reorder** — long-press any tile in the grid to reorder
- **Delete selected items** from the grid
- **Drag-to-dismiss** — swipe down to close (modal presentation only)
- **Comment box** — optional editable text field at the bottom
- **Upload progress overlay** — animated ring that auto-dismisses on completion
- **Share button** — one-tap `UIActivityViewController` for the current photo; fires `didTapShareButton` on the delegate
- **Long-press context menu** — Copy, Share, and Save to Photos actions on every photo
- **Per-photo captions** — set an optional `caption` label on any `PhotoAsset`
- **Page-change haptic** — optional selection pulse on every swipe (opt-in, off by default)
- **Glass theme** (iOS 26 Liquid Glass, default) and **Classic theme** (any tint color)
- **Adaptive appearance** — canvas and controls respond to system light/dark mode automatically
- **Smart navigation** — close button shown for modal presentation, hidden when pushed (system back button takes over); nav-bar controls (counter, Edit, Select) appear natively in the system navigation bar when pushed
- **Remote image loading** with in-memory LRU cache
- **PHAsset support** — load directly from the user's Photos library
- **Full VoiceOver / accessibility** support
- **Zero external dependencies**

---

## Requirements

| | Minimum |
|---|---|
| iOS | 15.0 |
| Swift | 5.9 |
| Xcode | 15.0 |

---

## Installation

### Xcode (recommended)

1. Open your project in Xcode
2. **File → Add Package Dependencies…**
3. Enter: `https://github.com/m-hamzak/HImageViewer.git`
4. Select **Up to Next Major Version** → **Add Package**

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/m-hamzak/HImageViewer.git", from: "1.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["HImageViewer"])
]
```

---

## Quick Start

### SwiftUI

```swift
import SwiftUI
import HImageViewer

struct ContentView: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(named: "photo")!))
    ]
    @State private var isPresented = false

    var body: some View {
        Button("Open Gallery") { isPresented = true }
            .fullScreenCover(isPresented: $isPresented) {
                HImageViewer(mediaAssets: $items)
            }
    }
}
```

### UIKit / Storyboard

```swift
import UIKit
import HImageViewer

class MyViewController: UIViewController {

    var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(named: "photo")!))
    ]

    @IBAction func openTapped(_ sender: Any) {
        HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
            self?.items = updated   // deletions and reorders sync back automatically
        }
    }
}
```

---

## SwiftUI Guide

### Photo gallery

```swift
import SwiftUI
import HImageViewer

struct GalleryView: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(named: "photo1")!)),
        .photo(PhotoAsset(image: UIImage(named: "photo2")!)),
        .photo(PhotoAsset(image: UIImage(named: "photo3")!)),
    ]
    @State private var isPresented = false

    var body: some View {
        Button("Open Gallery") { isPresented = true }
            .fullScreenCover(isPresented: $isPresented) {
                HImageViewer(mediaAssets: $items)
            }
    }
}
```

`items` stays in sync — deletions and reorders inside the viewer update your array automatically.

---

### Mixed photos and videos

```swift
@State private var items: [MediaAsset] = [
    .photo(PhotoAsset(image: UIImage(named: "cover")!)),
    .video(URL(string: "https://example.com/clip.mp4")!),
    .photo(PhotoAsset(imageURL: URL(string: "https://example.com/remote.jpg")!)),
]

HImageViewer(mediaAssets: $items)
```

---

### Open at a specific index

```swift
// Opens the viewer on the third item (index 2)
HImageViewer(mediaAssets: $items, initialIndex: 2)
```

---

### Loading from the Photos library (PHAsset)

```swift
import Photos

// Single asset
let item = MediaAsset.photo(PhotoAsset(phAsset: myPHAsset))

// From PHPickerViewController results
let photoAssets = PhotoAsset.from(phAssets: pickerResults.compactMap { $0.asset })
let items       = MediaAsset.from(photoAssets: photoAssets)

HImageViewer(mediaAssets: $items)
```

---

### Remote images

```swift
let item = MediaAsset.photo(PhotoAsset(imageURL: URL(string: "https://example.com/photo.jpg")!))
```

The viewer fetches on demand, caches in memory, shows a placeholder while loading, and an error view on failure. No extra setup required.

---

### With configuration

```swift
let config = HImageViewerConfiguration(
    tintColor: .orange,        // nil = Liquid Glass theme (default)
    showSaveButton: true,
    showCommentBox: true,
    initialComment: "Great shot!",
    showEditButton: true,
    delegate: self
)

HImageViewer(mediaAssets: $items, configuration: config)
```

---

### Delegate callbacks (SwiftUI)

Conform to `HImageViewerControlDelegate` to respond to user actions. All methods are optional.

```swift
class MyViewModel: HImageViewerControlDelegate {

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        // Called when the user taps Save.
        // `photos` = current photos in viewer, `comment` = comment box text.
        uploadToServer(photos: photos, caption: comment)
    }

    func didTapEditButton(photo: PhotoAsset) {
        // Called when the user taps Edit in single-photo mode.
        openEditor(for: photo)
    }

    func didTapCloseButton() {
        // Called when the viewer is dismissed.
        print("Viewer closed")
    }
}
```

Pass the delegate via configuration:

```swift
let config = HImageViewerConfiguration(delegate: myViewModel)
HImageViewer(mediaAssets: $items, configuration: config)
```

> **Note:** The viewer holds the delegate **weakly**. Make sure the object adopting the protocol is retained for the lifetime of the viewer session.

---

### Upload progress overlay

```swift
// 1. Create a shared state object
let uploadState = HImageViewerUploadState()

// 2. Pass it in configuration
let config = HImageViewerConfiguration(uploadState: uploadState)

// 3. Present the viewer
HImageViewer(mediaAssets: $items, configuration: config)

// 4. Drive the ring from your upload task
uploadState.progress = 0.0    // shows overlay
uploadState.progress = 0.45   // updates ring to 45%
uploadState.progress = 1.0    // completes and auto-dismisses the viewer
```

Set `uploadState.progress = nil` at any time to hide the overlay without dismissing.

---

### Custom placeholder and error views

```swift
let config = HImageViewerConfiguration(
    placeholderView: AnyView(
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading…").font(.caption).foregroundStyle(.secondary)
        }
    ),
    errorView: AnyView(
        Image(systemName: "photo.badge.exclamationmark")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    )
)
```

---

## Push vs Modal behaviour

`HImageViewer` automatically detects how it is presented and adjusts its UI accordingly — no configuration required.

| | Modal (`.sheet` / `fullScreenCover` / `present`) | Pushed (`navigationController.push`) |
|---|---|---|
| Close button | ✓ Shown (✕ in top-left) | Hidden — system Back button handles dismissal |
| Page counter & actions | Custom top bar inside the viewer | Native navigation bar (counter centred, Edit/Select trailing) |
| Drag-to-dismiss | ✓ Active | Disabled — system swipe-back handles it |

---

## UIKit & Storyboard Guide

All UIKit integration uses `HImageViewerLauncher` — no `UIHostingController` setup needed.

### Basic presentation

```swift
import UIKit
import HImageViewer

class MyViewController: UIViewController {

    let items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(named: "photo1")!)),
        .photo(PhotoAsset(image: UIImage(named: "photo2")!)),
    ]

    @IBAction func openGalleryTapped(_ sender: Any) {
        HImageViewerLauncher.present(from: self, mediaAssets: items)
    }
}
```

---

### Syncing changes back to your data model

By default the viewer shows your items but changes are not reflected in your array.  
Pass the `onChange` closure to stay in sync:

```swift
var items: [MediaAsset] = MediaAsset.from(uiImages: myImages)

HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
    self?.items = updated   // called after every delete or reorder
}
```

---

### Mixed photos and videos

```swift
var items: [MediaAsset] = [
    .photo(PhotoAsset(image: UIImage(named: "cover")!)),
    .video(URL(string: "https://example.com/clip.mp4")!),
]

HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
    self?.items = updated
}
```

---

### Open at a specific index

```swift
HImageViewerLauncher.present(from: self, mediaAssets: items, initialIndex: 2)
```

---

### Pushing onto a navigation stack

`HImageViewerLauncher` uses `present` for modal and `push` for navigation — choose based on your app's flow:

```swift
// Modal (default)
HImageViewerLauncher.present(from: self, mediaAssets: items)

// Pushed — viewer integrates into the existing nav bar
HImageViewerLauncher.push(from: self, mediaAssets: items)
```

When pushed, the viewer's page counter and Edit/Select buttons appear natively in the navigation bar. The system Back button handles dismissal; no close button is shown.

---

### With configuration

```swift
let config = HImageViewerConfiguration(
    tintColor: .systemBlue,
    showSaveButton: true,
    showCommentBox: true,
    initialComment: "Add a note…",
    delegate: self
)

HImageViewerLauncher.present(
    from: self,
    mediaAssets: items,
    configuration: config
) { [weak self] updated in
    self?.items = updated
}
```

---

### Delegate callbacks (UIKit)

```swift
class MyViewController: UIViewController, HImageViewerControlDelegate {

    var items: [MediaAsset] = []

    @IBAction func openGalleryTapped(_ sender: Any) {
        let config = HImageViewerConfiguration(
            showSaveButton: true,
            delegate: self
        )
        HImageViewerLauncher.present(from: self, mediaAssets: items, configuration: config)
    }

    // MARK: - HImageViewerControlDelegate

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        uploadToServer(photos: photos, caption: comment)
    }

    func didTapEditButton(photo: PhotoAsset) {
        let editor = MyEditorViewController(photo: photo)
        present(editor, animated: true)
    }

    func didTapCloseButton() {
        analytics.track("viewer_closed")
    }
}
```

---

### Upload progress overlay (UIKit)

```swift
class MyViewController: UIViewController {

    let uploadState = HImageViewerUploadState()
    var items: [MediaAsset] = []

    @IBAction func openAndUploadTapped(_ sender: Any) {
        let config = HImageViewerConfiguration(uploadState: uploadState)
        HImageViewerLauncher.present(from: self, mediaAssets: items, configuration: config)
        startUpload()
    }

    private func startUpload() {
        var p = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            p = min(p + 0.05, 1.0)
            self?.uploadState.progress = p
            if p >= 1.0 { timer.invalidate() }   // viewer auto-dismisses at 1.0
        }
    }
}
```

---

## Configuration Reference

`HImageViewerConfiguration()` with no arguments is valid — all parameters are optional.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tintColor` | `Color?` | `nil` | `nil` = Liquid Glass theme, accent inherits from the host app. Any `Color` = classic bordered style with that accent color. |
| `backgroundColor` | `Color` | `Color(.systemBackground)` | Canvas color drawn behind the photo/video content. Adapts to light/dark mode automatically. |
| `showSaveButton` | `Bool` | `true` | Shows the Save button in the bottom bar. |
| `showCommentBox` | `Bool` | `true` | Shows an editable comment field in the bottom bar. |
| `showEditButton` | `Bool` | `true` | Shows the Edit button in single-photo mode. |
| `showShareButton` | `Bool` | `true` | Shows the Share button in the top bar. Fires `didTapShareButton` and presents `UIActivityViewController` for the current photo. |
| `showContextMenu` | `Bool` | `true` | Shows a long-press context menu on photos with Copy, Share, and Save to Photos actions. |
| `pageChangeHaptic` | `Bool` | `false` | Fires a selection haptic on every page swipe. Opt in to match the native Photos-app feel. |
| `initialComment` | `String?` | `nil` | Pre-fills the comment box. |
| `title` | `String?` | `nil` | Static label shown when `showCommentBox` is `false`. |
| `uploadState` | `HImageViewerUploadState?` | `nil` | Drives the upload progress overlay. |
| `delegate` | `HImageViewerControlDelegate?` | `nil` | Receives save, edit, share, and close callbacks. |
| `placeholderView` | `AnyView?` | `nil` | Custom view while an image is loading. |
| `errorView` | `AnyView?` | `nil` | Custom view when an image fails to load. |

---

## Theming

### Liquid Glass (default)

Native iOS 26 Liquid Glass frosted-glass buttons and bars, with a polished material fallback for iOS 15–25. Adapts to the system light/dark mode automatically — no forced color scheme override. The accent color inherits from the host app's global `accentColor`, so buttons match the rest of your app with zero configuration.

```swift
HImageViewerConfiguration()   // tintColor defaults to nil → Glass mode
```

### Classic

Familiar bordered button style using any brand color. Setting `tintColor` switches the viewer into classic mode for all controls.

```swift
HImageViewerConfiguration(tintColor: .systemPurple)
HImageViewerConfiguration(tintColor: .orange)
HImageViewerConfiguration(tintColor: Color("BrandBlue"))
```

### Background color

The canvas behind the content defaults to `Color(.systemBackground)` (white in light mode, black in dark mode). Override it for a specific look:

```swift
// Always black — classic photo-viewer feel
HImageViewerConfiguration(backgroundColor: .black)

// Match your app's custom surface
HImageViewerConfiguration(backgroundColor: Color("AppSurface"))
```

---

## MediaAsset Reference

`MediaAsset` is the unified type for both photos and videos.

```swift
// Single items
let photo = MediaAsset.photo(PhotoAsset(image: myImage))
let video = MediaAsset.video(URL(string: "https://example.com/clip.mp4")!)

// Batch helpers
let photos = MediaAsset.from(uiImages: [img1, img2])
let videos  = MediaAsset.from(videoURLs: [url1, url2])
let gallery = photos + videos
```

### Inspecting content

```swift
switch asset.kind {
case .photo(let photoAsset): print("Photo id: \(photoAsset.id)")
case .video(let url):        print("Video url: \(url)")
}

asset.isPhoto     // Bool
asset.isVideo     // Bool
asset.photoAsset  // PhotoAsset? — nil for videos
asset.videoURL    // URL?        — nil for photos
```

---

## PhotoAsset Reference

| Initializer | Use when |
|-------------|----------|
| `PhotoAsset(image: UIImage)` | You already have a `UIImage` in memory |
| `PhotoAsset(phAsset: PHAsset)` | Loading from the user's Photos library |
| `PhotoAsset(imageURL: URL)` | Fetching from a remote server |

### Per-photo captions

Set an optional `caption` on any `PhotoAsset`. The viewer displays it as a subtitle below the photo when provided.

```swift
let asset = PhotoAsset(image: UIImage(named: "sunset")!, caption: "Golden hour in the Alps")
let asset = PhotoAsset(imageURL: remoteURL, caption: "Lake Tahoe, CA")
```

### Load error inspection

After a URL-based photo fails to load, `loadError` is set to the underlying `Error`. Use it to show a custom error message or decide whether to retry.

```swift
asset.loadFullImage { image in
    if image == nil, let error = asset.loadError {
        print("Failed to load: \(error.localizedDescription)")
    }
}
```

`loadError` is always `nil` for `UIImage`-backed assets and is automatically cleared when a new load starts.

### Batch helpers

```swift
// [UIImage] → [PhotoAsset]
let assets = PhotoAsset.from(uiImages: [img1, img2, img3])

// [PHAsset] → [PhotoAsset]
let assets = PhotoAsset.from(phAssets: [phAsset1, phAsset2])

// Wrap directly as MediaAsset
let items = MediaAsset.from(uiImages: [img1, img2])
// or from PHAssets:
let items = MediaAsset.from(photoAssets: PhotoAsset.from(phAssets: [phAsset1]))
```

---

## Delegate Reference

All methods have default no-op implementations — adopt only what you need.

```swift
public protocol HImageViewerControlDelegate: AnyObject {

    /// Called when the user taps Save.
    /// - `photos`: Every photo currently in the viewer (videos excluded).
    /// - `comment`: Text from the comment box (empty string if hidden).
    func didTapSaveButton(comment: String, photos: [PhotoAsset])

    /// Called when the user taps Edit in single-photo mode.
    /// Only fires when `showEditButton` is `true` in configuration.
    func didTapEditButton(photo: PhotoAsset)

    /// Called when the viewer is dismissed via the close button or drag-to-dismiss (modal only).
    func didTapCloseButton()

    /// Called after the user deletes one or more items via the selection grid.
    /// - `assets`: The items that were removed.
    func didDeleteMediaAssets(_ assets: [MediaAsset])

    /// Called every time the visible page changes (swipe or programmatic).
    /// - `index`: Zero-based index of the newly visible item.
    func didChangePage(to index: Int)

    /// Called when the user taps the Share button or chooses Share from the context menu.
    /// The viewer also presents UIActivityViewController automatically.
    /// - `photos`: The photo(s) being shared. Single-photo mode = one item;
    ///   selection mode = every selected photo.
    func didTapShareButton(photos: [PhotoAsset])
}
```

---

## Share & Context Menu

### Share button

The Share button appears in the top bar when `showShareButton` is `true` (default). Tapping it presents `UIActivityViewController` for the current photo and fires `didTapShareButton` on the delegate.

```swift
let config = HImageViewerConfiguration(
    showShareButton: true,
    delegate: self
)

// In your delegate:
func didTapShareButton(photos: [PhotoAsset]) {
    analytics.track("photo_shared", count: photos.count)
}
```

To disable the Share button:

```swift
HImageViewerConfiguration(showShareButton: false)
```

### Context menu

Long-press any photo to reveal a context menu with three actions:

- **Copy** — copies the image to the pasteboard
- **Share** — same as tapping the Share button
- **Save to Photos** — saves the image to the user's Photos library

```swift
// Disable context menus entirely:
HImageViewerConfiguration(showContextMenu: false)
```

---

## Video playback

Videos are played using `AVKit` with native transport controls. The viewer automatically:

- Configures the `AVAudioSession` to `.playback` / `.moviePlayback` so video audio mixes correctly with your app
- Observes `AVPlayerItem.status` via Combine and shows a custom error overlay if the stream fails to load
- Provides a **Retry** button in the error overlay to reload the stream without dismissing the viewer

```swift
// Mixed gallery with a video
let items: [MediaAsset] = [
    .photo(PhotoAsset(image: UIImage(named: "cover")!)),
    .video(URL(string: "https://example.com/clip.mp4")!),
]
HImageViewer(mediaAssets: $items)
```

No extra configuration is required for video. The audio session is set up automatically when the player first loads.

---

## License

```
MIT License

Copyright (c) 2025 Hamza Khalid

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

Created and maintained by [Muhammad Hamza Khalid](https://github.com/m-hamzak)
