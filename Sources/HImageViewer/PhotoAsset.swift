//
//  PhotoAsset.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import UIKit
import Photos

public class PhotoAsset: Identifiable, Equatable {
    public let id = UUID()
    public let phAsset: PHAsset?
    public var image: UIImage?
    public var isSelected: Bool = false

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

            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, _ in
                completion(result)
            }
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

            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { result, _ in
                completion(result)
            }
        } else {
            completion(nil)
        }
    }

    // Equatable support
    public static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.id == rhs.id
    }
}

extension PhotoAsset {
    public static func from(uiImages: [UIImage]) -> [PhotoAsset] {
        uiImages.map { PhotoAsset(image: $0) }
    }

    public static func from(phAssets: [PHAsset]) -> [PhotoAsset] {
        phAssets.map { PhotoAsset(phAsset: $0) }
    }
}

