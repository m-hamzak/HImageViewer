//
//  MediaAsset.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import UIKit

/// A unified media item that wraps either a photo or a video, for use in `HImageViewer`.
///
/// `MediaAsset` lets you mix photos and videos in a single gallery. Each instance carries a stable
/// `UUID` so SwiftUI can use it safely in `ForEach` collections.
///
/// ## Creating assets
///
/// ```swift
/// let photo = MediaAsset.photo(PhotoAsset(image: myImage))
/// let video = MediaAsset.video(URL(string: "https://example.com/clip.mp4")!)
/// let gallery: [MediaAsset] = [photo, video]
/// ```
///
/// ## Batch factory methods
///
/// ```swift
/// let photos = MediaAsset.from(uiImages: [img1, img2])
/// let videos  = MediaAsset.from(videoURLs: [url1, url2])
/// ```
///
/// ## Switching on content
///
/// ```swift
/// switch asset.kind {
/// case .photo(let photoAsset): // handle photo
/// case .video(let url):        // handle video
/// }
/// ```
///
/// - Note: Equality is based on the stable `id` UUID, not the wrapped content.
public struct MediaAsset: Identifiable, Equatable {

    // MARK: - Kind

    /// The underlying content type of a `MediaAsset`.
    public enum Kind: Equatable {
        /// A photo, backed by a `PhotoAsset`.
        case photo(PhotoAsset)
        /// A remote or local video, referenced by a `URL`.
        case video(URL)
    }

    // MARK: - Properties

    /// A stable unique identifier for this media item.
    public let id: UUID

    /// The underlying content — either `.photo` or `.video`.
    public let kind: Kind

    // MARK: - Initialisation

    /// Creates a `MediaAsset` with an explicit `id` and content `kind`.
    ///
    /// In most cases, prefer the static convenience factories
    /// (`MediaAsset.photo(_:)` / `MediaAsset.video(_:)`) over this initialiser.
    ///
    /// - Parameters:
    ///   - id: A stable UUID for this asset. Defaults to a freshly generated one.
    ///   - kind: The content to wrap — `.photo` or `.video`.
    public init(id: UUID = UUID(), kind: Kind) {
        self.id = id
        self.kind = kind
    }

    // MARK: - Convenience factories (single item)

    /// Creates a photo `MediaAsset` from a `PhotoAsset`.
    public static func photo(_ asset: PhotoAsset) -> MediaAsset {
        MediaAsset(kind: .photo(asset))
    }

    /// Creates a video `MediaAsset` from a `URL`.
    public static func video(_ url: URL) -> MediaAsset {
        MediaAsset(kind: .video(url))
    }

    // MARK: - Content accessors

    /// The wrapped `PhotoAsset`, or `nil` if this is a video asset.
    public var photoAsset: PhotoAsset? {
        guard case .photo(let asset) = kind else { return nil }
        return asset
    }

    /// The wrapped video `URL`, or `nil` if this is a photo asset.
    public var videoURL: URL? {
        guard case .video(let url) = kind else { return nil }
        return url
    }

    /// `true` when this asset wraps a photo.
    public var isPhoto: Bool { photoAsset != nil }

    /// `true` when this asset wraps a video.
    public var isVideo: Bool { videoURL != nil }

    // MARK: - Equatable

    /// Two `MediaAsset`s are equal if and only if their `id`s are equal.
    public static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Batch factory methods

@MainActor
public extension MediaAsset {

    /// Creates an array of photo `MediaAsset`s from `UIImage` instances.
    ///
    /// - Parameter uiImages: Images to wrap.
    /// - Returns: One `MediaAsset.photo` per image, each with a unique `id`.
    static func from(uiImages: [UIImage]) -> [MediaAsset] {
        uiImages.map { .photo(PhotoAsset(image: $0)) }
    }

    /// Creates an array of photo `MediaAsset`s from `PhotoAsset` instances.
    ///
    /// - Parameter photoAssets: Photo assets to wrap.
    /// - Returns: One `MediaAsset.photo` per asset, preserving the asset's own `id`.
    static func from(photoAssets: [PhotoAsset]) -> [MediaAsset] {
        photoAssets.map { .photo($0) }
    }

    /// Creates an array of video `MediaAsset`s from remote or local `URL`s.
    ///
    /// - Parameter videoURLs: URLs to wrap.
    /// - Returns: One `MediaAsset.video` per URL, each with a unique `id`.
    static func from(videoURLs: [URL]) -> [MediaAsset] {
        videoURLs.map { .video($0) }
    }
}
