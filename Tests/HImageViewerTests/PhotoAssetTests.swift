//
//  PhotoAssetTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class PhotoAssetTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_initWithImage_setsImageAndNilPhAssetAndNilURL() {
        let img = UIImage(systemName: "star")!
        let asset = PhotoAsset(image: img)

        XCTAssertNotNil(asset.image, "Image should be set immediately")
        XCTAssertNil(asset.phAsset, "phAsset should be nil when init with UIImage")
        XCTAssertNil(asset.imageURL, "imageURL should be nil when init with UIImage")
    }

    func test_initWithImage_generatesUniqueID() {
        let img = UIImage(systemName: "star")!
        let a = PhotoAsset(image: img)
        let b = PhotoAsset(image: img)

        XCTAssertNotEqual(a.id, b.id, "Each PhotoAsset must have a unique UUID")
    }

    func test_initWithURL_setsURLAndNilImageAndNilPhAsset() {
        let url = URL(string: "https://example.com/photo.jpg")!
        let asset = PhotoAsset(imageURL: url)

        XCTAssertEqual(asset.imageURL, url, "URL should be stored exactly as passed")
        XCTAssertNil(asset.image, "Image should be nil until loaded from URL")
        XCTAssertNil(asset.phAsset, "phAsset should be nil when init with URL")
    }

    // MARK: - Equatable Tests

    func test_equatable_sameInstance_isEqual() {
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        XCTAssertEqual(asset, asset, "An asset should be equal to itself")
    }

    func test_equatable_differentInstances_areNotEqual() {
        let img = UIImage(systemName: "star")!
        let a = PhotoAsset(image: img)
        let b = PhotoAsset(image: img)

        XCTAssertNotEqual(a, b, "Different instances should NOT be equal (different UUIDs)")
    }

    // MARK: - Identifiable Tests

    func test_identifiable_idIsStableAcrossAccesses() {
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        let id1 = asset.id
        let id2 = asset.id
        XCTAssertEqual(id1, id2, "ID must be stable — same value every time")
    }

    // MARK: - Image Loading Tests (Cached Path)

    func test_loadThumbnail_withPreloadedImage_returnsImmediately() {
        let img = UIImage(systemName: "star")!
        let asset = PhotoAsset(image: img)
        var result: UIImage?

        // This should complete synchronously (image already cached)
        asset.loadThumbnail(targetSize: CGSize(width: 100, height: 100)) { image in
            result = image
        }

        // Because it's synchronous, result is available immediately
        XCTAssertNotNil(result, "Cached image should be returned immediately")
    }

    func test_loadThumbnail_urlAsset_cacheMiss_doesNotCompleteSync() {
        // Cache miss for a URL asset starts an async Task — completion must NOT fire synchronously.
        let url = URL(string: "https://example.com/img-\(UUID()).jpg")!
        ImageCache.shared[url] = nil  // ensure cache miss
        let asset = PhotoAsset(imageURL: url)

        var completionFired = false
        asset.loadThumbnail(targetSize: CGSize(width: 100, height: 100)) { _ in
            completionFired = true
        }

        XCTAssertFalse(completionFired, "Cache miss must not complete synchronously")
    }

    func test_loadFullImage_withPreloadedImage_returnsImmediately() {
        let img = UIImage(systemName: "star")!
        let asset = PhotoAsset(image: img)
        var result: UIImage?

        asset.loadFullImage { image in
            result = image
        }

        XCTAssertNotNil(result, "Cached image should be returned immediately from loadFullImage")
    }

    func test_loadFullImage_urlAsset_cacheMiss_doesNotCompleteSync() {
        // Cache miss for a URL asset starts an async Task — completion must NOT fire synchronously.
        let url = URL(string: "https://example.com/img-\(UUID()).jpg")!
        ImageCache.shared[url] = nil  // ensure cache miss
        let asset = PhotoAsset(imageURL: url)

        var completionFired = false
        asset.loadFullImage { _ in
            completionFired = true
        }

        XCTAssertFalse(completionFired, "Cache miss must not complete synchronously")
    }

    // MARK: - Factory Method Tests

    func test_fromUIImages_returnsCorrectCount() {
        let images = [
            UIImage(systemName: "star")!,
            UIImage(systemName: "heart")!,
            UIImage(systemName: "circle")!
        ]
        let assets = PhotoAsset.from(uiImages: images)
        XCTAssertEqual(assets.count, 3, "Should create one asset per image")
    }

    func test_fromUIImages_eachAssetHasImage() {
        let images = [UIImage(systemName: "star")!, UIImage(systemName: "heart")!]
        let assets = PhotoAsset.from(uiImages: images)

        for (index, asset) in assets.enumerated() {
            XCTAssertNotNil(asset.image, "Asset at index \(index) should have a non-nil image")
        }
    }

    func test_fromUIImages_emptyArray_returnsEmpty() {
        let assets = PhotoAsset.from(uiImages: [])
        XCTAssertTrue(assets.isEmpty, "Empty input should produce empty output")
    }

    func test_fromUIImages_allAssetsHaveUniqueIDs() {
        let images = [UIImage(systemName: "star")!, UIImage(systemName: "heart")!]
        let assets = PhotoAsset.from(uiImages: images)

        let uniqueIDs = Set(assets.map(\.id))
        XCTAssertEqual(uniqueIDs.count, assets.count, "All assets must have unique IDs")
    }

    // MARK: - URL Cache-Hit Tests

    func test_loadFullImage_urlAsset_cacheHit_returnsImmediately() {
        let url = URL(string: "https://example.com/cached.jpg")!
        let cachedImage = UIImage(systemName: "star")!
        ImageCache.shared[url] = cachedImage

        let asset = PhotoAsset(imageURL: url)
        var result: UIImage?

        asset.loadFullImage { image in
            result = image
        }

        // Cache hit path is synchronous — result available immediately
        XCTAssertNotNil(result, "Cache hit must return image synchronously")
        XCTAssertNotNil(asset.image, "Cache hit must also set asset.image")

        // Cleanup
        ImageCache.shared[url] = nil
    }

    func test_loadThumbnail_urlAsset_cacheHit_returnsImmediately() {
        let url = URL(string: "https://example.com/thumb-cached.jpg")!
        let cachedImage = UIImage(systemName: "heart")!
        ImageCache.shared[url] = cachedImage

        let asset = PhotoAsset(imageURL: url)
        var result: UIImage?

        asset.loadThumbnail(targetSize: CGSize(width: 100, height: 100)) { image in
            result = image
        }

        XCTAssertNotNil(result, "loadThumbnail for URL with cache hit must return immediately")

        // Cleanup
        ImageCache.shared[url] = nil
    }

    func test_loadFullImage_urlAsset_cacheMiss_doesNotReturnImmediately() {
        let url = URL(string: "https://example.com/not-cached-\(UUID()).jpg")!
        ImageCache.shared[url] = nil // ensure cache miss

        let asset = PhotoAsset(imageURL: url)
        var callbackFired = false

        asset.loadFullImage { _ in
            callbackFired = true
        }

        // Cache miss starts an async task — callback has NOT fired yet synchronously
        XCTAssertFalse(callbackFired, "Cache miss must not complete synchronously")
    }

    // MARK: - cancelPendingLoad

    func test_cancelPendingLoad_safeWhenNothingPending() {
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        // Must not crash
        asset.cancelPendingLoad()
    }

    func test_cancelPendingLoad_afterURLLoad_doesNotCrash() {
        let url = URL(string: "https://example.com/cancel-test.jpg")!
        let asset = PhotoAsset(imageURL: url)

        // Start a network load then immediately cancel
        asset.loadFullImage { _ in }
        asset.cancelPendingLoad()
        // Reaching here = no crash
    }
}
