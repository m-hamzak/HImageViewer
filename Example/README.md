# HIImageViewer Example App

A runnable iOS app demonstrating every major feature of HImageViewer.

## Running the example

1. Open `HIImageViewerExample.xcodeproj` in Xcode
2. Wait for the package dependency (`HImageViewer` from GitHub) to resolve
3. Select an iPhone simulator and press **Run**

> If you want to use your local development version instead of the published package,
> drag the root `HIImageViewer` package folder into the example project's "Frameworks, Libraries,
> and Embedded Content" section, then remove the remote package reference.

## What's covered

| Screen | Feature demonstrated |
|--------|---------------------|
| Photo Gallery | Basic `[MediaAsset]` photo gallery, delete & reorder |
| Mixed Media | Photos + video in the same gallery |
| Remote Images | URL-based lazy loading with in-memory cache |
| Glass Theme | Default Liquid Glass controls (iOS 16+) |
| Classic Theme | Branded color with `tintColor: .orange` |
| Upload Progress | `HImageViewerUploadState` animated ring, auto-dismiss |
| With Delegate | All five `HImageViewerControlDelegate` callbacks |
| UIKit Launcher | `HImageViewerLauncher.present` and `.push` from UIKit |
