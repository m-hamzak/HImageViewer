//
//  HImageViewerUploadState.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 11/07/2025.
//

import Foundation

/// Observable state object for tracking upload progress in `HImageViewer`.
///
/// Create an instance of this class, pass it via `HImageViewerConfiguration`, and update
/// the `progress` property from your upload code. The viewer will automatically display
/// a progress overlay and dismiss when complete.
///
/// ## Example
/// ```swift
/// // Create shared upload state
/// let uploadState = HImageViewerUploadState()
///
/// // Pass to viewer
/// let config = HImageViewerConfiguration(uploadState: uploadState)
/// HImageViewer(assets: $assets, selectedVideo: $video, configuration: config)
///
/// // Update progress during upload
/// uploadState.progress = 0.5  // 50% complete
/// uploadState.progress = 1.0  // Complete - viewer auto-dismisses
/// ```
///
/// - Important: Set `progress` to `nil` to hide the progress overlay without dismissing.
public class HImageViewerUploadState: ObservableObject {
    /// Current upload progress value.
    ///
    /// - `nil`: No upload in progress (progress overlay hidden)
    /// - `0.0...1.0`: Upload in progress (shows progress overlay)
    /// - `1.0`: Upload complete (viewer auto-dismisses after brief delay)
    @Published public var progress: Double? = nil

    /// Creates a new upload state tracker.
    ///
    /// - Parameter progress: Initial progress value (default: `nil` for no upload)
    public init(progress: Double? = nil) {
        self.progress = progress
    }
}
