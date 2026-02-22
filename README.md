# HImageViewer

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/github/license/m-hamzak/HImageViewer.svg)](https://github.com/m-hamzak/HImageViewer/blob/main/LICENSE)

# 📷 HImageViewer

A SwiftUI + UIKit-compatible image and video viewer component with support for:

✅ Single & multi-photo modes  
✅ Video playback  
✅ Optional editable comment box or static title  
✅ Optional Save button  
✅ Selection mode for multi-photo delete  
✅ Orientation handling & full-screen presentation  
✅ Delegates for UIKit integration  
✅ iOS 15+ & Apple Silicon ready

---

## 🆕 What's New in 1.0.1

### Critical Fixes
- 🐛 Fixed crash risks from force unwraps and unsafe array access
- 🔒 Thread-safe image loading preventing data races and UI warnings
- 💾 Memory leak fixes with proper request cancellation and cleanup
- ⚡ Better performance with async/await image loading

### Improvements
- ✨ Auto-dismiss when all photos deleted
- 🧹 Cleaner, more maintainable codebase
- 📖 Fixed `initialComment` configuration now works correctly

See [CHANGELOG.md](./CHANGELOG.md) for full details.

---

## ✨ Features

- 📷 **Single & Multiple Photo Modes**
  - Single photo with optional comment box or static title
  - Multi-photo grid with selection and delete


- 🎥 **Video Support**
  - Plays a provided `URL` in full-screen with `AVPlayer`


- 📝 **Comment & Title**
  - Editable comment box in single-photo mode
  - Or static title if comment box is disabled


- 💾 **Optional Save Button**
  - Configurable via initializer


- 🚀 **Fully Configurable**
  - SwiftUI-friendly, also works in UIKit


- 🌗 **Orientation Support**
  - Works in portrait & landscape seamlessly


- 🖇️ **Delegate Callbacks**
  - For close, save, and edit actions

---

## 📲 Installation

### Swift Package Manager (SPM)

Add this to your `Package.swift`:
```swift
.package(url: "https://github.com/m-hamzak/HImageViewer.git", from: "1.0.2")
```

or in Xcode:
- File → Swift Packages → Add Package Dependency…
- Enter:
  ```
  https://github.com/m-hamzak/HImageViewer.git
  ```

---

## 🛠 Usage

### ✅ In SwiftUI
```swift
@State var assets: [PhotoAsset] = [
    PhotoAsset(image: UIImage(named: "sample1")!),
    PhotoAsset(image: UIImage(named: "sample2")!)
]
@State var selectedVideo: URL? = nil

HImageViewer(
    assets: $assets,
    selectedVideo: $selectedVideo,
    configuration: .init(
        title: "My Photo Gallery",
        showCommentBox: false,
        showSaveButton: true,
        delegate: self
    )
)
```

---

### ✅ In UIKit

Use the provided launcher to present in UIKit:

```swift
ImageViewerLauncher.present(
    from: self,
    assets: assets,
    selectedVideo: videoURL,
    configuration: .init(
        title: "Sample Gallery",
        showCommentBox: false,
        showSaveButton: true,
        delegate: self
    )
)
```

---

## 📋 Configuration

Pass `HImageViewerConfiguration` when initializing:
```swift
HImageViewerConfiguration(
    initialComment: "Pre-filled comment",
    delegate: self,
    showCommentBox: true,
    showSaveButton: true,
    title: "Static Title"
)
```

| Property            | Description |
|----------------------|-------------|
| `initialComment`     | Initial text in comment box |
| `title`              | Shown instead of comment box if `showCommentBox` is `false` |
| `showCommentBox`      | Show editable comment field |
| `showSaveButton`      | Show Save button |
| `delegate`           | Handle callbacks from viewer |

---

## 👨‍💻 Delegate

```swift
protocol ImageViewerDelegate: AnyObject {
    func didTapCloseButton()
    func didTapSaveButton(comment: String, photos: [PhotoAsset])
    func didTapEditButton()
}
```

---

## 📦 Screenshots

| Single Photo | Multi Photo Grid | Video |
|--------------|------------------|-------|
| ![](Screenshots/single-photo.png) | ![](Screenshots/multi-photo-grid.png) | ![](Screenshots/video-player.png) |

---

### Notes
✅ Orientation support confirmed.  
✅ Progress indicator planned but not baked in yet (external via delegate).  
✅ Comment box & title mutually exclusive.  
✅ Save button optional.  
✅ UIKit delegate callbacks for closing, saving, editing.

---



## Contributing

Contributions are welcome. Feel free to fork the repo, submit pull requests, or open issues for feature requests and bug reports.

---

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

Created and maintained by [Muhammad Hamza Khalid](https://www.linkedin.com/in/m-hamzak/)  
[GitHub](https://github.com/m-hamzak)


