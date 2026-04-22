//
//  PhotoAsset.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import UIKit
import Photos

/// A model representing a photo asset that can be displayed in `HImageViewer`.
///
/// `PhotoAsset` supports three initialization modes:
/// - From a `PHAsset` (Photos framework asset)
/// - From a `UIImage` (direct image)
/// - From a remote `URL` (network image)
///
/// The class handles asynchronous image loading and provides thumbnail and full-size image loading capabilities.
///
/// ## Usage
///
/// ### From UIImage:
/// ```swift
/// let asset = PhotoAsset(image: myUIImage)
/// ```
///
/// ### From PHAsset:
/// ```swift
/// let asset = PhotoAsset(phAsset: myPHAsset)
/// asset.loadFullImage { image in
///     // Use loaded image
/// }
/// ```
///
/// ### From remote URL:
/// ```swift
/// let asset = PhotoAsset(imageURL: myURL)
/// ```
///
/// - Important: Image loading is performed asynchronously and automatically managed by the viewer.
/// - Note: This class is annotated with `@MainActor` to ensure thread-safe UI updates.
@MainActor
public class PhotoAsset: ObservableObject, Identifiable, Equatable {

    // MARK: - Properties

    public let id = UUID()
    public let phAsset: PHAsset?
    @Published public var image: UIImage?
    public let imageURL: URL?

    // Track active requests for cancellation
    private var currentRequestID: PHImageRequestID?
    private var urlLoadTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a photo asset from a Photos framework asset.
    ///
    /// Use this initializer when working with photos from the user's photo library via `PHPickerViewController` or Photos framework.
    ///
    /// - Parameter phAsset: The Photos framework asset to wrap.
    ///
    /// - Note: The actual image is loaded lazily when needed via `loadThumbnail(targetSize:completion:)` or `loadFullImage(completion:)`.
    public init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.image = nil
        self.imageURL = nil
    }

    /// Creates a photo asset from a UIImage.
    ///
    /// Use this initializer when you have an image directly available (e.g., from camera capture or generated image).
    ///
    /// - Parameter image: The UIImage to display.
    public init(image: UIImage) {
        self.image = image
        self.phAsset = nil
        self.imageURL = nil
    }

    /// Creates a photo asset from a remote image URL.
    ///
    /// Use this initializer for images hosted on a server or remote location.
    ///
    /// - Parameter imageURL: The URL of the remote image to load.
    ///
    /// - Note: The image is loaded asynchronously when the viewer displays this asset.
    public init(imageURL: URL) {
        self.imageURL = imageURL
        self.phAsset = nil
        self.image = nil
    }

    // MARK: - Image Loading

    /// Loads a thumbnail-sized version of the image asynchronously.
    ///
    /// - `UIImage` assets return immediately.
    /// - `PHAsset` assets use `PHImageManager` with fast-format delivery.
    /// - URL assets delegate to `loadFullImage` — the cached full image is returned on subsequent calls.
    ///
    /// - Parameters:
    ///   - targetSize: Desired thumbnail size for `PHAsset` requests.
    ///   - completion: Called on the main thread with the loaded image, or `nil` on failure.
    ///
    /// - Note: Call `cancelPendingLoad()` to cancel an in-flight request.
    public func loadThumbnail(targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        if let image = image {
            completion(image)
        } else if let phAsset = phAsset {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            let requestID = PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] result, _ in
                self?.currentRequestID = nil
                completion(result)
            }
            currentRequestID = requestID
        } else if imageURL != nil {
            // URL assets have no native thumbnail — delegate to full load.
            // Subsequent calls will hit the in-memory cache immediately.
            loadFullImage(completion: completion)
        } else {
            completion(nil)
        }
    }

    /// Loads the full-resolution version of the image asynchronously.
    ///
    /// - `UIImage` assets return immediately.
    /// - `PHAsset` assets use `PHImageManager` with high-quality delivery.
    /// - URL assets check `ImageCache` first; on a miss, fetches via `URLSession` and populates the cache.
    ///
    /// - Parameter completion: Called on the main thread with the loaded image, or `nil` on failure.
    ///
    /// - Note: Call `cancelPendingLoad()` to cancel an in-flight request.
    public func loadFullImage(completion: @escaping (UIImage?) -> Void) {
        if let image = image {
            completion(image)
            return
        }

        if let phAsset = phAsset {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            let targetSize = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)

            let requestID = PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] result, _ in
                self?.currentRequestID = nil
                completion(result)
            }
            currentRequestID = requestID
            return
        }

        if let url = imageURL {
            // Cache hit — return synchronously
            if let cached = ImageCache.shared[url] {
                image = cached
                completion(cached)
                return
            }
            // Cache miss — fetch from network
            urlLoadTask?.cancel()
            urlLoadTask = Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard !Task.isCancelled else { return }
                    if let loaded = UIImage(data: data) {
                        ImageCache.shared[url] = loaded
                        self.image = loaded
                        completion(loaded)
                    } else {
                        completion(nil)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    completion(nil)
                }
            }
            return
        }

        completion(nil)
    }

    // MARK: - Cancellation

    /// Cancels any in-flight image load (URL fetch or PHAsset request).
    ///
    /// Call this when the view displaying this asset disappears to avoid
    /// redundant network and Photos framework activity.
    public func cancelPendingLoad() {
        urlLoadTask?.cancel()
        urlLoadTask = nil
        if let requestID = currentRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            currentRequestID = nil
        }
    }

    // MARK: - Equatable

    nonisolated public static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.id == rhs.id
    }

    // Only cancel the URLSession task here — it is Sendable and safe to cancel from any thread.
    // PHImageManager requests are cancelled in cancelPendingLoad(), which is called from
    // PhotoView.onDisappear on the main actor. Calling PHImageManager from deinit is unsafe
    // because deinit runs on whichever thread releases the last reference, not the main actor.
    deinit {
        urlLoadTask?.cancel()
    }
}

// MARK: - Convenience Methods

@MainActor
extension PhotoAsset {
    /// Convenience method to create an array of `PhotoAsset` from UIImages.
    ///
    /// - Parameter uiImages: Array of UIImages to convert.
    /// - Returns: Array of `PhotoAsset` objects.
    public static func from(uiImages: [UIImage]) -> [PhotoAsset] {
        uiImages.map { PhotoAsset(image: $0) }
    }

    /// Convenience method to create an array of `PhotoAsset` from PHAssets.
    ///
    /// - Parameter phAssets: Array of PHAssets from Photos framework.
    /// - Returns: Array of `PhotoAsset` objects.
    public static func from(phAssets: [PHAsset]) -> [PhotoAsset] {
        phAssets.map { PhotoAsset(phAsset: $0) }
    }
}

