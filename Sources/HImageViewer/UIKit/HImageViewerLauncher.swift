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
/// ## Example
/// ```swift
/// class MyViewController: UIViewController {
///     var items: [MediaAsset] = [
///         .photo(PhotoAsset(image: myImage)),
///         .video(videoURL)
///     ]
///
///     func showGallery() {
///         HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
///             self?.items = updated   // deletions and reorders sync back automatically
///         }
///     }
/// }
/// ```
public final class HImageViewerLauncher {

    // MARK: - Present (modal)

    /// Presents the viewer modally from a UIKit view controller.
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

    // MARK: - Push (navigation stack)

    /// Pushes the viewer onto the nearest navigation controller.
    ///
    /// When pushed, the viewer integrates with the system navigation bar:
    /// the page counter and action buttons (Edit, Select) appear as native
    /// navigation bar items, and the close button is hidden — the system
    /// Back button handles dismissal instead.
    ///
    /// - Parameters:
    ///   - viewController: A view controller embedded in a `UINavigationController`.
    ///     Silent no-op if no navigation controller is found.
    ///   - mediaAssets: Array of `MediaAsset` items to display.
    ///   - initialIndex: The index of the item to open first. Defaults to `0`.
    ///   - configuration: Configuration object for customizing viewer behavior.
    ///   - onChange: Called every time the media asset array changes.
    @MainActor public static func push(
        from viewController: UIViewController,
        mediaAssets: [MediaAsset],
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init(),
        onChange: (([MediaAsset]) -> Void)? = nil
    ) {
        guard let nav = viewController.navigationController else { return }
        let container = MediaViewerContainer(
            mediaAssets: mediaAssets,
            initialIndex: initialIndex,
            configuration: configuration,
            onChange: onChange
        )
        nav.pushViewController(UIHostingController(rootView: container), animated: true)
    }
}

// MARK: - Internal container view
// `internal` (not `private`) so the type is reachable from `@testable` unit tests
// while remaining hidden from the package's public API.

/// Owns the `@State` for the viewer and bridges mutations back via `onChange`.
struct MediaViewerContainer: View {
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
