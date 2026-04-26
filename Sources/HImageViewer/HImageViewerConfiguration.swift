//
//  HImageViewerConfiguration.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 08/07/2025.
//

import SwiftUI

/// Configuration object for customizing `HImageViewer` behavior and appearance.
///
/// Use this struct to configure the viewer's UI elements, delegate callbacks, upload progress
/// tracking, and visual theming.
///
/// ## Example
/// ```swift
/// let config = HImageViewerConfiguration(
///     tintColor: .purple,
///     showSaveButton: true,
///     showCommentBox: true,
///     showEditButton: false,
///     initialComment: "My vacation photos",
///     title: "Photo Gallery",
///     delegate: self,
///     placeholderView: AnyView(MyLoadingView()),
///     errorView: AnyView(MyErrorView())
/// )
///
/// HImageViewer(mediaAssets: $items, configuration: config)
/// ```
public struct HImageViewerConfiguration {

    // MARK: - Content

    /// Initial text to pre-fill in the comment box when `showCommentBox` is enabled.
    public let initialComment: String?

    /// Delegate to receive callbacks for user interactions (save, close, edit).
    ///
    /// - Important: Do not retain this configuration object long-term. Pass it directly to
    ///   `HImageViewer` to avoid potential retain cycles. The viewer stores the delegate weakly.
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
    /// Pass a shared `HImageViewerUploadState` instance and update its `progress` property
    /// (0.0–1.0) from your upload code. The viewer automatically shows/hides a progress overlay.
    public let uploadState: HImageViewerUploadState?

    // MARK: - Theming

    /// The canvas color drawn behind the photo/video content.
    ///
    /// Defaults to `Color(.systemBackground)` so the viewer feels at home in both
    /// light mode (white canvas) and dark mode (black canvas) without any extra
    /// configuration. Pass any `Color` to override:
    ///
    /// ```swift
    /// // Always black (classic photo-viewer look)
    /// HImageViewerConfiguration(backgroundColor: .black)
    ///
    /// // Match your app's surface color
    /// HImageViewerConfiguration(backgroundColor: Color("AppBackground"))
    /// ```
    public let backgroundColor: Color

    /// The accent color applied to interactive elements: buttons, icons, and the loading spinner.
    ///
    /// - When `nil` (default): the viewer uses the native iOS 26 Liquid Glass theme — a dark,
    ///   immersive look with frosted-glass buttons and bars.
    /// - When set to any `Color`: the viewer switches to a classic bordered style using that
    ///   color as the accent (button icons, action button, text cursor).
    ///
    /// ```swift
    /// // Glass theme (default)
    /// HImageViewerConfiguration()
    ///
    /// // Classic themed style
    /// HImageViewerConfiguration(tintColor: .purple)
    /// ```
    public let tintColor: Color?

    /// A custom view displayed while a photo is loading.
    ///
    /// When `nil` (default), the viewer shows a gray background with a system `ProgressView`.
    /// Provide any `AnyView` to completely replace the built-in placeholder.
    ///
    /// ```swift
    /// placeholderView: AnyView(
    ///     VStack {
    ///         ProgressView()
    ///         Text("Loading…").font(.caption)
    ///     }
    /// )
    /// ```
    public let placeholderView: AnyView?

    /// A custom view displayed when a photo fails to load.
    ///
    /// When `nil` (default), the viewer shows a red background with a warning triangle icon.
    /// Provide any `AnyView` to completely replace the built-in error state.
    ///
    /// ```swift
    /// errorView: AnyView(
    ///     Image(systemName: "photo.badge.exclamationmark")
    ///         .font(.largeTitle)
    ///         .foregroundColor(.secondary)
    /// )
    /// ```
    public let errorView: AnyView?

    // MARK: - Derived helpers

    /// `true` when the viewer should use the iOS 26 Liquid Glass theme.
    /// `false` when a custom `tintColor` was supplied, enabling the classic bordered style.
    public var isGlassMode: Bool { tintColor == nil }

    /// The effective accent color. Returns the provided `tintColor`, or the host app's
    /// global accent color when none is set — so the viewer automatically matches the
    /// developer's app theme without any extra configuration.
    public var resolvedTintColor: Color { tintColor ?? .accentColor }

    // MARK: - Initialisation

    /// Creates a new configuration with the specified options.
    ///
    /// - Parameters:
    ///   - tintColor: Accent color. `nil` (default) = Liquid Glass theme. Any `Color` = classic bordered style.
    ///   - backgroundColor: Canvas color behind content. Defaults to `Color(.systemBackground)`
    ///     so the viewer adapts to light/dark mode automatically.
    ///   - showSaveButton: Show Save button (default: `true`)
    ///   - showCommentBox: Show editable comment field (default: `true`)
    ///   - showEditButton: Show Edit button in single photo mode (default: `true`)
    ///   - initialComment: Initial text for comment box (default: `nil`)
    ///   - title: Static title when comment box is hidden (default: `nil`)
    ///   - uploadState: Shared upload progress tracker (default: `nil`)
    ///   - delegate: Delegate for user interaction callbacks (default: `nil`)
    ///   - placeholderView: Custom view shown while an image loads (default: `nil`)
    ///   - errorView: Custom view shown when an image fails to load (default: `nil`)
    public init(
        tintColor: Color? = nil,
        backgroundColor: Color = Color(.systemBackground),
        showSaveButton: Bool = true,
        showCommentBox: Bool = true,
        showEditButton: Bool = true,
        initialComment: String? = nil,
        title: String? = nil,
        uploadState: HImageViewerUploadState? = nil,
        delegate: HImageViewerControlDelegate? = nil,
        placeholderView: AnyView? = nil,
        errorView: AnyView? = nil
    ) {
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.showSaveButton = showSaveButton
        self.showCommentBox = showCommentBox
        self.showEditButton = showEditButton
        self.initialComment = initialComment
        self.title = title
        self.uploadState = uploadState
        self.delegate = delegate
        self.placeholderView = placeholderView
        self.errorView = errorView
    }
}
