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
    public var imageURL: URL?

    // Track active image requests for cancellation
    private var currentRequestID: PHImageRequestID?

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
    }

    /// Creates a photo asset from a UIImage.
    ///
    /// Use this initializer when you have an image directly available (e.g., from camera capture or generated image).
    ///
    /// - Parameter image: The UIImage to display.
    public init(image: UIImage) {
        self.image = image
        self.phAsset = nil
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
    /// This method is optimized for fast loading and is suitable for grid views or lists.
    ///
    /// - Parameters:
    ///   - targetSize: The desired size for the thumbnail. The actual size may vary to maintain aspect ratio.
    ///   - completion: Called on the main thread with the loaded image, or `nil` if loading fails.
    ///
    /// - Note: If the image is already loaded, the completion handler is called immediately with the cached image.
    /// - Important: Pending requests are automatically cancelled when the asset is deallocated.
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
        } else {
            completion(nil)
        }
    }

    /// Loads the full-resolution version of the image asynchronously.
    ///
    /// This method requests the highest quality image available and is suitable for single photo viewing.
    ///
    /// - Parameter completion: Called on the main thread with the loaded image, or `nil` if loading fails.
    ///
    /// - Note: If the image is already loaded, the completion handler is called immediately with the cached image.
    /// - Important: Pending requests are automatically cancelled when the asset is deallocated.
    public func loadFullImage(completion: @escaping (UIImage?) -> Void) {
        if let image = image {
            completion(image)
        } else if let phAsset = phAsset {
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
        } else {
            completion(nil)
        }
    }

    // MARK: - Equatable

    nonisolated public static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.id == rhs.id
    }

    // Cancel any pending image requests on deallocation
    deinit {
        if let requestID = currentRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
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

