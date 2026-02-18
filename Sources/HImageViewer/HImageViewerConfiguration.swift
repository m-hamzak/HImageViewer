//
//  HImageViewerConfiguration.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 08/07/2025.
//

/// Configuration object for customizing `HImageViewer` behavior and appearance.
///
/// Use this struct to configure the viewer's UI elements, delegate callbacks, and upload progress tracking.
///
/// ## Example
/// ```swift
/// let config = HImageViewerConfiguration(
///     initialComment: "My vacation photos",
///     delegate: self,
///     showCommentBox: true,
///     showSaveButton: true,
///     showEditButton: false,
///     title: "Photo Gallery"
/// )
///
/// HImageViewer(assets: $assets, selectedVideo: $video, configuration: config)
/// ```
public struct HImageViewerConfiguration {
    /// Initial text to pre-fill in the comment box when `showCommentBox` is enabled.
    public let initialComment: String?

    /// Delegate to receive callbacks for user interactions (save, close, edit).
    ///
    /// - Important: Do not retain this configuration object long-term. Pass it directly to `HImageViewer`
    ///   to avoid potential retain cycles. The viewer extracts and stores the delegate with a weak reference.
    public let delegate: HImageViewerControlDelegate?

    /// Whether to show an editable comment text field. If `false`, displays static `title` instead.
    public let showCommentBox: Bool

    /// Whether to show the Save button in the bottom bar.
    public let showSaveButton: Bool

    /// Whether to show the Edit button in single photo mode.
    public let showEditButton: Bool

    /// Static title text displayed when `showCommentBox` is `false`.
    public let title: String?

    /// Shared upload state object for tracking and displaying upload progress.
    ///
    /// Pass a shared `HImageViewerUploadState` instance and update its `progress` property (0.0-1.0)
    /// from your upload code. The viewer will automatically show/hide a progress overlay.
    public let uploadState: HImageViewerUploadState?

    /// Creates a new configuration with the specified options.
    ///
    /// - Parameters:
    ///   - initialComment: Initial text for comment box (default: `nil`)
    ///   - delegate: Delegate for user interaction callbacks (default: `nil`)
    ///   - showCommentBox: Show editable comment field (default: `true`)
    ///   - showSaveButton: Show Save button (default: `true`)
    ///   - showEditButton: Show Edit button in single photo mode (default: `true`)
    ///   - title: Static title when comment box is hidden (default: `nil`)
    ///   - uploadState: Shared upload progress tracker (default: `nil`)
    public init(
        initialComment: String? = nil,
        delegate: HImageViewerControlDelegate? = nil,
        showCommentBox: Bool = true,
        showSaveButton: Bool = true,
        showEditButton: Bool = true,
        title: String? = nil,
        uploadState: HImageViewerUploadState? = nil
    ) {
        self.initialComment = initialComment
        self.delegate = delegate
        self.showCommentBox = showCommentBox
        self.showSaveButton = showSaveButton
        self.showEditButton = showEditButton
        self.title = title
        self.uploadState = uploadState
    }
}
