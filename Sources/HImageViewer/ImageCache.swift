//
//  ImageCache.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import UIKit

/// Shared in-memory image cache for URL-loaded assets.
///
/// Automatically evicts entries under memory pressure via `NSCache`.
/// Keyed by the URL's absolute string.
final class ImageCache: @unchecked Sendable {

    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 100
        c.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return c
    }()

    private init() {}

    subscript(url: URL) -> UIImage? {
        get {
            cache.object(forKey: url.absoluteString as NSString)
        }
        set {
            let key = url.absoluteString as NSString
            if let image = newValue {
                // Cost approximation: width × height × 4 bytes per pixel
                let cost = Int(image.size.width * image.size.height * 4)
                cache.setObject(image, forKey: key, cost: cost)
            } else {
                cache.removeObject(forKey: key)
            }
        }
    }

    /// Removes all cached images.
    func removeAll() {
        cache.removeAllObjects()
    }
}
