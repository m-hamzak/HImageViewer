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
/// Use this launcher to easily present the SwiftUI-based image viewer from UIKit code.
///
/// ## Example
/// ```swift
/// class MyViewController: UIViewController {
///     func showGallery() {
///         let assets = PhotoAsset.from(uiImages: myImages)
///         let config = HImageViewerConfiguration(
///             showSaveButton: true,
///             delegate: self
///         )
///
///         ImageViewerLauncher.present(
///             from: self,
///             assets: assets,
///             configuration: config
///         )
///     }
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
    ///
    /// - Note: The viewer is presented full-screen with a modal presentation style.
    /// - Important: Changes to `assets` after presentation won't be reflected in the viewer (uses constant binding).
    @MainActor public static func present(
        from viewController: UIViewController,
        assets: [PhotoAsset],
        selectedVideo: URL? = nil,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        let viewer = HImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(selectedVideo),
            initialIndex: initialIndex,
            configuration: configuration
        )

        let hostingController = UIHostingController(rootView: viewer)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }

    // MARK: - Mixed photo + video

    /// Presents the viewer with a mixed array of photos and videos.
    ///
    /// Use this overload when you want to display `MediaAsset` items (photos and/or videos)
    /// in the same gallery session.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present from.
    ///   - mediaAssets: Array of `MediaAsset` items (photos and/or videos) to display.
    ///   - initialIndex: The index of the item to open first. Defaults to `0`.
    ///   - configuration: Configuration object for customizing viewer behavior.
    ///
    /// - Note: The viewer is presented full-screen with a modal presentation style.
    /// - Important: Changes to `mediaAssets` after presentation won't be reflected in the viewer (uses constant binding).
    @MainActor public static func present(
        from viewController: UIViewController,
        mediaAssets: [MediaAsset],
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        let viewer = HImageViewer(
            mediaAssets: .constant(mediaAssets),
            initialIndex: initialIndex,
            configuration: configuration
        )

        let hostingController = UIHostingController(rootView: viewer)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }
}
