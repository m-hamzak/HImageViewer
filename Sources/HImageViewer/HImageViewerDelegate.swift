//
//  HImageViewerDelegate.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 24/04/2025.
//

/// Protocol for handling user interactions with the image viewer.
///
/// All methods have default no-op implementations — adopt only what you need.
///
/// ## Example
/// ```swift
/// class MyViewController: UIViewController, HImageViewerControlDelegate {
///
///     func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
///         saveToDB(photos: photos, comment: comment)
///     }
///
///     func didDeleteMediaAssets(_ assets: [MediaAsset]) {
///         syncDeletion(assets)
///     }
///
///     func didChangePage(to index: Int) {
///         print("Now viewing item \(index)")
///     }
///
///     func didTapCloseButton() {
///         print("Viewer closed")
///     }
///
///     func didTapEditButton(photo: PhotoAsset) {
///         presentEditor(for: photo)
///     }
/// }
/// ```
public protocol HImageViewerControlDelegate: AnyObject {

    /// Called when the user taps the Save button.
    ///
    /// - Parameters:
    ///   - comment: The text entered in the comment box, or empty string if the comment box is disabled.
    ///   - photos: Every photo currently displayed in the viewer (videos are excluded).
    func didTapSaveButton(comment: String, photos: [PhotoAsset])

    /// Called when the user taps the close button or dismisses via drag-to-dismiss.
    func didTapCloseButton()

    /// Called when the user taps the Edit button in single-photo mode.
    ///
    /// - Parameter photo: The photo asset that should be edited.
    /// - Note: Only fires when `showEditButton` is `true` in configuration.
    func didTapEditButton(photo: PhotoAsset)

    /// Called after the user deletes one or more items via the selection grid.
    ///
    /// - Parameter assets: The items that were removed from the viewer.
    func didDeleteMediaAssets(_ assets: [MediaAsset])

    /// Called every time the visible page changes.
    ///
    /// Fires both when the user swipes to a new page and when the index is adjusted
    /// programmatically (e.g. after a deletion clamps the index).
    ///
    /// - Parameter index: The zero-based index of the newly visible item.
    func didChangePage(to index: Int)

    /// Called when the user taps the Share button or chooses *Share* from the context menu.
    ///
    /// The viewer also presents `UIActivityViewController` automatically, but you can
    /// use this callback to record analytics or add custom share logic.
    ///
    /// - Parameter photos: The photo(s) being shared. In single-photo mode this is
    ///   always one item; in selection mode it contains every selected photo.
    func didTapShareButton(photos: [PhotoAsset])
}

// MARK: - Default Implementations

public extension HImageViewerControlDelegate {
    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {}
    func didTapCloseButton() {}
    func didTapEditButton(photo: PhotoAsset) {}
    func didDeleteMediaAssets(_ assets: [MediaAsset]) {}
    func didChangePage(to index: Int) {}
    func didTapShareButton(photos: [PhotoAsset]) {}
}
