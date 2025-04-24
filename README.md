Here’s the cleaned-up and professional version of your `README.md`, with unnecessary emojis removed and helpful badges added:

---

# HImageViewer

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/github/license/m-hamzak/HImageViewer.svg)](https://github.com/m-hamzak/HImageViewer/blob/main/LICENSE)

**HImageViewer** is a lightweight Swift package for displaying, managing, and interacting with photos and videos in iOS apps using SwiftUI and UIKit.

---

## Features

- Automatically detects single or multiple photo mode
- Smooth thumbnail loading for better performance
- Video playback support
- Photo grid view with selection capability
- Comment support in single photo mode
- Photo deletion and "Add more" actions
- Delegate-based callbacks for better control
- Modular and easy to integrate

---

## Installation

Using **Swift Package Manager**:

1. In Xcode, go to **File > Add Packages**
2. Paste the repository URL:
   ```
   https://github.com/m-hamzak/HImageViewer.git
   ```
3. Choose the version or branch, then click "Add Package"

---

## Getting Started

### 1. Import the Package

```swift
import HImageViewer
```

### 2. Prepare State Variables

```swift
@State private var assets: [PhotoAsset] = []
@State private var selectedVideo: URL? = nil
@State private var showViewer = false
```

### 3. Present the Viewer

```swift
.fullScreenCover(isPresented: $showViewer) {
    ImageViewer(
        assets: $assets,
        selectedVideo: $selectedVideo,
        delegate: self
    )
}
```

> The viewer automatically switches between single-photo or multi-photo modes based on the number of assets provided.

---

## PhotoAsset Usage

Use `PhotoAsset` to wrap `UIImage` or `PHAsset` objects:

```swift
// Using UIImages
let uiImages: [UIImage] = [...]
let assets = PhotoAsset.from(uiImages: uiImages)

// Using PHAssets
let phAssets: [PHAsset] = [...]
let assets = PhotoAsset.from(phAssets: phAssets)
```

---

## Delegate Methods

Conform to `ImageViewerDelegate` for callback handling:

```swift
func didSaveComment(_ comment: String)
```

---

## Components

| Component            | Description                             |
|----------------------|-----------------------------------------|
| `ImageViewer`        | Main entry point, auto mode switching   |
| `PhotoAsset`         | Abstraction for photos and videos       |
| `MultiPhotoGrid`     | Grid layout for multiple photos         |
| `ThumbnailImageView` | Efficient thumbnail loading             |
| `PhotoView`          | Shows thumbnail or original image       |
| `VideoPlayerView`    | SwiftUI-friendly video playback         |

---

## Example Use Cases

- Fullscreen image or video preview
- Editable photo galleries
- Photo commenting interface
- Dynamic gallery with add/delete functionality

---

## Roadmap

- [ ] Gesture-based zoom and pan
- [ ] Custom UI theming support
- [ ] In-app image editor integration

---

## Contributing

Contributions are welcome. Feel free to fork the repo, submit pull requests, or open issues for feature requests and bug reports.

---

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

Created and maintained by [Muhammad Hamza Khalid](https://www.linkedin.com/in/m-hamzak/)  
[GitHub](https://github.com/m-hamzak)

---

Let me know if you want to include a demo GIF or usage screenshots in the README as well — that can help showcase the package even better!
