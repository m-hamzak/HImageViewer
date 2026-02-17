//
//  PhotoAsset.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import UIKit
import Photos

@MainActor
public class PhotoAsset: ObservableObject, Identifiable, Equatable {
    public let id = UUID()
    public let phAsset: PHAsset?
    @Published public var image: UIImage?
    public var imageURL: URL?
    public var isSelected: Bool = false

    // Track active image requests for cancellation
    private var currentRequestID: PHImageRequestID?

    // Init with PHAsset (e.g., from PHPickerViewController)
    public init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.image = nil
    }

    // Init with direct UIImage (e.g., from camera)
    public init(image: UIImage) {
        self.image = image
        self.phAsset = nil
    }
    
    public init(imageURL: URL) {
        self.imageURL = imageURL
        self.phAsset = nil
        self.image = nil
    }

    // Load thumbnail image
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
                DispatchQueue.main.async {
                    self?.currentRequestID = nil
                    completion(result)
                }
            }
            currentRequestID = requestID
        } else {
            completion(nil)
        }
    }

    // Load full-size image
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
                DispatchQueue.main.async {
                    self?.currentRequestID = nil
                    completion(result)
                }
            }
            currentRequestID = requestID
        } else {
            completion(nil)
        }
    }

    // Equatable support
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

@MainActor
extension PhotoAsset {
    public static func from(uiImages: [UIImage]) -> [PhotoAsset] {
        uiImages.map { PhotoAsset(image: $0) }
    }

    public static func from(phAssets: [PHAsset]) -> [PhotoAsset] {
        phAssets.map { PhotoAsset(phAsset: $0) }
    }
}

