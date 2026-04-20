//
//  HImageViewerLauncher.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 22/04/2025.
//

import SwiftUI
import UIKit

/// Utility class for presenting `HImageViewer` from UIKit view controllers.
///
/// Use this launcher to present the SwiftUI-based image viewer from any UIKit
/// context — including Storyboard-based apps — with a single method call.
///
/// ## Photo-only example
/// ```swift
/// class MyViewController: UIViewController {
///     var photos = PhotoAsset.from(uiImages: myImages)
///
///     func showGallery() {
///         HImageViewerLauncher.present(from: self, assets: photos) { [weak self] updated in
///             self?.photos = updated   // deletions and reorders sync back automatically
///         }
///     }
/// }
/// ```
///
/// ## Mixed photo + video example
/// ```swift
/// HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
///     self?.items = updated
/// }
/// ```
public final class HImageViewerLauncher {

    // MARK: - Photo-only (legacy)

    /// Presents the image viewer modally from a UIKit view controller.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present from.
    ///   - assets: Array of photo assets to display.
    ///   - selectedVideo: Optional video URL to display instead of photos.
    ///   - initialIndex: The index of the photo to open first. Defaults to `0`.
    ///   - configuration: Configuration object for customizing viewer behavior.
    ///   - onChange: Called every time the asset array changes (e.g. after a
    ///     deletion or reorder). Use this closure to keep your own data model in
    ///     sync. Pass `nil` (default) if you don't need change notifications.
    @MainActor public static func present(
        from viewController: UIViewController,
        assets: [PhotoAsset],
        selectedVideo: URL? = nil,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init(),
        onChange: (([PhotoAsset]) -> Void)? = nil
    ) {
        let container = PhotoViewerContainer(
            assets: assets,
            selectedVideo: selectedVideo,
            initialIndex: initialIndex,
            configuration: configuration,
            onChange: onChange
        )
        let hostingController = UIHostingController(rootView: container)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }

    // MARK: - Mixed photo + video

    /// Presents the viewer with a mixed array of photos and videos.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present from.
    ///   - mediaAssets: Array of `MediaAsset` items (photos and/or videos) to display.
    ///   - initialIndex: The index of the item to open first. Defaults to `0`.
    ///   - configuration: Configuration object for customizing viewer behavior.
    ///   - onChange: Called every time the media asset array changes (e.g. after a
    ///     deletion or reorder). Use this closure to keep your own data model in
    ///     sync. Pass `nil` (default) if you don't need change notifications.
    @MainActor public static func present(
        from viewController: UIViewController,
        mediaAssets: [MediaAsset],
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init(),
        onChange: (([MediaAsset]) -> Void)? = nil
    ) {
        let container = MediaViewerContainer(
            mediaAssets: mediaAssets,
            initialIndex: initialIndex,
            configuration: configuration,
            onChange: onChange
        )
        let hostingController = UIHostingController(rootView: container)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }
}

// MARK: - Private container views

/// Owns the `@State` for photo-only mode and bridges mutations back via `onChange`.
private struct PhotoViewerContainer: View {
    @State var assets: [PhotoAsset]
    @State var selectedVideo: URL?
    let initialIndex: Int
    let configuration: HImageViewerConfiguration
    let onChange: (([PhotoAsset]) -> Void)?

    var body: some View {
        HImageViewer(
            assets: $assets,
            selectedVideo: $selectedVideo,
            initialIndex: initialIndex,
            configuration: configuration
        )
        .onChangeCompat(of: assets) { onChange?($0) }
    }
}

/// Owns the `@State` for media mode and bridges mutations back via `onChange`.
private struct MediaViewerContainer: View {
    @State var mediaAssets: [MediaAsset]
    let initialIndex: Int
    let configuration: HImageViewerConfiguration
    let onChange: (([MediaAsset]) -> Void)?

    var body: some View {
        HImageViewer(
            mediaAssets: $mediaAssets,
            initialIndex: initialIndex,
            configuration: configuration
        )
        .onChangeCompat(of: mediaAssets) { onChange?($0) }
    }
}
