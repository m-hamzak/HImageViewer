//
//  HImageViewerDelegate.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 24/04/2025.
//

/// Protocol for handling user interactions with the image viewer.
///
/// Implement this protocol to respond to save, close, and edit actions within the viewer.
///
/// ## Example
/// ```swift
/// class MyViewController: UIViewController, HImageViewerControlDelegate {
///     func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
///         // Save photos with comment
///         saveToDB(photos: photos, comment: comment)
///     }
///
///     func didTapCloseButton() {
///         // Handle viewer dismissal
///         print("Viewer closed")
///     }
///
///     func didTapEditButton(photo: PhotoAsset) {
///         // Present image editor
///         presentEditor(for: photo)
///     }
/// }
/// ```
public protocol HImageViewerControlDelegate: AnyObject {
    /// Called when the user taps the Save button.
    ///
    /// - Parameters:
    ///   - comment: The text entered in the comment box, or empty string if comment box is disabled.
    ///   - photos: Array of all photos currently displayed in the viewer.
    ///
    /// - Note: This method is called even if the comment box is disabled (comment will be empty).
    func didTapSaveButton(comment: String, photos: [PhotoAsset])

    /// Called when the user taps the close button to dismiss the viewer.
    ///
    /// - Note: The viewer automatically dismisses itself; use this method for cleanup or analytics.
    func didTapCloseButton()

    /// Called when the user taps the Edit button in single photo mode.
    ///
    /// - Parameter photo: The photo asset that should be edited.
    ///
    /// - Important: Only called in single photo mode when `showEditButton` is enabled.
    func didTapEditButton(photo: PhotoAsset)
}

// MARK: - Default Implementations

/// Default implementations allow selective protocol adoption.
///
/// Implement only the methods you need - other methods will use these no-op defaults.
public extension HImageViewerControlDelegate {
    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {}
    func didTapCloseButton() {}
    func didTapEditButton(photo: PhotoAsset) {}
}
