# ``HImageViewer``

A SwiftUI and UIKit media viewer for photos and videos with Liquid Glass and classic themes.

## Overview

`HImageViewer` is a drop-in media viewer that displays a paged gallery of photos and videos. It supports:

- **Liquid Glass theme** (default, iOS 26) — frosted-glass controls that blend into any background.
- **Classic theme** — bordered buttons tinted with any `Color` you choose.
- **Zoom-to-point** — double-tap zooms into the exact tap location; pinch to zoom up to 5×.
- **Share sheet** — one-tap `UIActivityViewController` for the current photo or selected items.
- **Long-press context menu** — Copy, Share, or Save to Photos without leaving the viewer.
- **Upload progress** — animated ring overlay that auto-dismisses on completion.
- **Selection and reorder** — multi-select grid with drag-to-reorder support.

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
