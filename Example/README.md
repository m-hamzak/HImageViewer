# HIImageViewer Example App

A runnable iOS app demonstrating every major feature of HImageViewer.

## Running the example

### Using the local package (recommended for development)

1. Open `HIImageViewerExample.xcodeproj` in Xcode
2. The project already references the local `HImageViewer` package from the parent folder — no extra setup needed
3. Select an iPhone simulator and press **Run**

### Switching to the published package

If you want to use the released version instead of the local source:

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter: `https://github.com/m-hamzak/HImageViewer.git`
3. Select **Up to Next Major Version → 1.1.0 → Add Package**
4. Remove the local package reference from **Frameworks, Libraries, and Embedded Content**

## What's covered

| Screen | Feature demonstrated |
|--------|---------------------|
| Photo Gallery | Basic `[MediaAsset]` photo gallery, delete & reorder in grid |
| Mixed Media | Photos + video in the same gallery |
| Remote Images | URL-based lazy loading with in-memory LRU cache |
| Photo Captions | Per-photo `caption` label on `PhotoAsset` |
| Glass Theme | Default iOS 26 Liquid Glass controls (polished material fallback on iOS 15–25) |
| Classic Theme | Branded color with `tintColor: .orange` |
| Upload Progress | `HImageViewerUploadState` animated ring, auto-dismiss at 100% |
| Haptic & Share | `pageChangeHaptic: true` + `showShareButton: true` + `didTapShareButton` delegate |
| Context Menu | `showContextMenu: true` — long-press Copy / Share / Save to Photos |
| With Delegate | All six `HImageViewerControlDelegate` callbacks |
| UIKit Launcher | `HImageViewerLauncher.present` and `.push` from UIKit |
