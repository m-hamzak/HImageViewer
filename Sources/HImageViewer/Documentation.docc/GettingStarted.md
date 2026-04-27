# Getting Started with HImageViewer

Add a full-featured photo and video viewer to your app in minutes.

## Installation

Add the package via Xcode: **File → Add Package Dependencies** and enter:

```
https://github.com/m-hamzak/HImageViewer.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/m-hamzak/HImageViewer.git", from: "1.1.0")
]
```

## SwiftUI integration

### Basic gallery

```swift
import HImageViewer

struct ContentView: View {
    @State private var assets = MediaAsset.from(uiImages: [
        UIImage(named: "photo1")!,
        UIImage(named: "photo2")!,
    ])
    @State private var isPresented = false

    var body: some View {
        Button("Open Gallery") { isPresented = true }
            .fullScreenCover(isPresented: $isPresented) {
                HImageViewer(mediaAssets: $assets)
            }
    }
}
```

### Remote images

```swift
let assets: [MediaAsset] = [
    .photo(PhotoAsset(imageURL: URL(string: "https://example.com/photo.jpg")!)),
    .photo(PhotoAsset(imageURL: URL(string: "https://example.com/photo2.jpg")!)),
]
```

### Mixed photos and videos

```swift
let assets: [MediaAsset] = [
    .photo(PhotoAsset(image: UIImage(named: "cover")!)),
    .video(URL(string: "https://example.com/clip.mp4")!),
]
```

### Photos with captions

```swift
let assets: [MediaAsset] = [
    .photo(PhotoAsset(image: photo1, caption: "Sunset at Maldives")),
    .photo(PhotoAsset(image: photo2, caption: "Morning hike")),
]
```

### PHAsset (Photos framework)

```swift
let photoAssets = PhotoAsset.from(phAssets: phResults.objects())
let assets      = MediaAsset.from(photoAssets: photoAssets)
```

## Themes

### Liquid Glass (default)

```swift
HImageViewer(mediaAssets: $assets)
```

### Classic tinted

```swift
HImageViewer(
    mediaAssets: $assets,
    configuration: HImageViewerConfiguration(tintColor: .orange)
)
```

## Configuration options

```swift
let config = HImageViewerConfiguration(
    tintColor: .purple,          // nil = Liquid Glass (default)
    backgroundColor: .black,     // canvas behind the image
    showSaveButton: true,
    showCommentBox: true,
    showEditButton: true,
    showShareButton: true,       // share button in top bar
    showContextMenu: true,       // long-press context menu
    pageChangeHaptic: true,      // selection haptic on every swipe
    initialComment: "My photos",
    title: "Gallery",            // shown when showCommentBox is false
    uploadState: myUploadState,
    delegate: self
)
```

## Delegate callbacks

All methods have default no-op implementations — implement only what you need.

```swift
class MyController: HImageViewerControlDelegate {

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        upload(photos, comment: comment)
    }

    func didTapEditButton(photo: PhotoAsset) {
        present(EditorViewController(photo: photo), animated: true)
    }

    func didTapShareButton(photos: [PhotoAsset]) {
        analytics.track("share", count: photos.count)
    }

    func didTapCloseButton() { }

    func didDeleteMediaAssets(_ assets: [MediaAsset]) {
        syncDeletion(assets)
    }

    func didChangePage(to index: Int) {
        prefetch(index + 1)
    }
}
```

Pass the delegate via configuration:

```swift
let config = HImageViewerConfiguration(delegate: myController)
HImageViewer(mediaAssets: $assets, configuration: config)
```

> The viewer holds the delegate **weakly**. Keep the adopting object alive for the duration of the viewer session.

## Upload progress

```swift
let uploadState = HImageViewerUploadState()

HImageViewer(
    mediaAssets: $assets,
    configuration: HImageViewerConfiguration(uploadState: uploadState)
)

// From your upload code:
uploadState.progress = 0.5   // 50%
uploadState.progress = 1.0   // complete — viewer auto-dismisses
```

## Video playback

Pass any direct-stream URL as a `.video` asset. The viewer configures the `AVAudioSession` automatically so video audio mixes correctly with your app.

```swift
let assets: [MediaAsset] = [
    .photo(PhotoAsset(image: UIImage(named: "poster")!)),
    .video(URL(string: "https://example.com/clip.mp4")!),
]
```

If the stream fails to load, a built-in error overlay appears with a **Retry** button — no extra configuration required.

## Push vs modal

`HImageViewer` detects its presentation context automatically and adjusts its UI:

| Context | Close button | Controls |
|---------|-------------|----------|
| Modal (`.fullScreenCover` / `present`) | ✓ Shown (✕ top-left) | Custom top bar inside the viewer |
| Pushed (`navigationController.push`) | Hidden — system Back takes over | Native navigation bar |

```swift
// Modal — SwiftUI
.fullScreenCover(isPresented: $isPresented) {
    HImageViewer(mediaAssets: $assets)
}

// Pushed — UIKit
HImageViewerLauncher.push(from: self, mediaAssets: assets)
```

Drag-to-dismiss (swipe down) is active in modal context; the system swipe-back handles pushed context.

## UIKit integration

### Modal presentation

```swift
HImageViewerLauncher.present(
    from: self,
    mediaAssets: assets,
    configuration: HImageViewerConfiguration(tintColor: .systemBlue)
) { updatedAssets in
    self.assets = updatedAssets   // deletions and reorders sync back
}
```

### Push onto a navigation stack

```swift
HImageViewerLauncher.push(from: self, mediaAssets: assets)
```

When pushed, the viewer's page counter and Edit / Select buttons appear natively in the navigation bar.
