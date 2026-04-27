# ``HImageViewer``

A SwiftUI and UIKit media viewer for photos and videos with Liquid Glass and classic themes.

## Overview

`HImageViewer` is a drop-in media viewer that displays a paged gallery of photos and videos. It supports:

- **Liquid Glass theme** (default, iOS 26) — frosted-glass controls that blend into any background, with a polished material fallback for iOS 15–25.
- **Classic theme** — bordered buttons tinted with any `Color` you choose.
- **Pinch-to-zoom & zoom-to-point** — double-tap zooms into the exact tap location; pinch to zoom up to 5×.
- **Native video playback** — AVKit transport controls with automatic `AVAudioSession` setup and a built-in error-recovery overlay with Retry.
- **Share sheet** — one-tap `UIActivityViewController` for the current photo or selected items.
- **Long-press context menu** — Copy, Share, or Save to Photos without leaving the viewer.
- **Per-photo captions** — optional subtitle label on any `PhotoAsset`.
- **Page-change haptic** — opt-in selection pulse on every swipe, matching the native Photos app.
- **Upload progress** — animated ring overlay that auto-dismisses on completion.
- **Multi-select & reorder** — checkmark grid with drag-to-reorder support and bulk delete.
- **Drag-to-dismiss** — swipe down to close in modal context; swipe-back handles pushed context.
- **Remote image loading** — URL-based lazy loading with in-memory LRU cache, placeholder, and error view.
- **PHAsset support** — load directly from the user's Photos library.
- **Smart navigation** — automatically detects push vs modal and adjusts controls accordingly.
- **Full VoiceOver / accessibility** support throughout.

## Quick start

```swift
import HImageViewer

struct MyView: View {
    @State private var assets: [MediaAsset] = MediaAsset.from(uiImages: myImages)
    @State private var isPresented = false

    var body: some View {
        Button("Open Gallery") { isPresented = true }
            .fullScreenCover(isPresented: $isPresented) {
                HImageViewer(mediaAssets: $assets)
            }
    }
}
```

## Topics

### Getting started

- <doc:GettingStarted>

### Core viewer

- ``HImageViewer``
- ``HImageViewerConfiguration``

### Media model

- ``MediaAsset``
- ``PhotoAsset``

### Delegate

- ``HImageViewerControlDelegate``

### Upload progress

- ``HImageViewerUploadState``

### UIKit integration

- ``HImageViewerLauncher``
