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

    // MARK: - URL init properties

    func test_initWithURL_phAssetIsNilAndImageIsNil() {
        let url = URL(string: "https://example.com/props.jpg")!
        let asset = PhotoAsset(imageURL: url)
        XCTAssertNil(asset.phAsset)
        XCTAssertNil(asset.image)
        XCTAssertNotNil(asset.imageURL)
    }

    // MARK: - ID immutability

    func test_id_doesNotChangeAfterImageReplaced() {
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        let before = asset.id
        asset.image = UIImage(systemName: "heart")!
        XCTAssertEqual(asset.id, before, "id must never change")
    }

    func test_id_doesNotChangeAfterImageCleared() {
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        let before = asset.id
        asset.image = nil
        XCTAssertEqual(asset.id, before)
    }

    // MARK: - loadFullImage: pre-loaded called synchronously twice

    func test_loadFullImage_calledTwiceOnPreloadedAsset_firesTwice() {
        let img = UIImage(systemName: "star")!
        let asset = PhotoAsset(image: img)
        var callCount = 0
        asset.loadFullImage { _ in callCount += 1 }
        asset.loadFullImage { _ in callCount += 1 }
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - loadThumbnail: pre-loaded fires synchronously twice

    func test_loadThumbnail_calledTwiceOnPreloadedAsset_firesTwice() {
        let img = UIImage(systemName: "star")!
        let asset = PhotoAsset(image: img)
        var callCount = 0
        let size = CGSize(width: 100, height: 100)
        asset.loadThumbnail(targetSize: size) { _ in callCount += 1 }
        asset.loadThumbnail(targetSize: size) { _ in callCount += 1 }
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - Cache hit sets asset.image

    func test_loadFullImage_cacheHit_setsAssetImage() {
        let url = URL(string: "https://example.com/sets-image-\(UUID()).jpg")!
        let img  = UIImage(systemName: "star")!
        ImageCache.shared[url] = img
        let asset = PhotoAsset(imageURL: url)
        XCTAssertNil(asset.image)
        asset.loadFullImage { _ in }
        XCTAssertNotNil(asset.image, "Cache hit must set asset.image synchronously")
        ImageCache.shared[url] = nil
    }

    // MARK: - cancelPendingLoad is idempotent

    func test_cancelPendingLoad_calledTwice_doesNotCrash() {
        let url  = URL(string: "https://example.com/cancel-twice-\(UUID()).jpg")!
        let asset = PhotoAsset(imageURL: url)
        asset.loadFullImage { _ in }
        asset.cancelPendingLoad()
        asset.cancelPendingLoad()   // second cancel — must not crash
    }

    func test_cancelPendingLoad_beforeAnyLoad_doesNotCrash() {
        let url  = URL(string: "https://example.com/cancel-before-\(UUID()).jpg")!
        let asset = PhotoAsset(imageURL: url)
        asset.cancelPendingLoad()   // nothing pending
    }

    // MARK: - from(uiImages:) image content

    func test_fromUIImages_firstAssetHasNonNilImage() {
        let img    = UIImage(systemName: "star")!
        let assets = PhotoAsset.from(uiImages: [img])
        XCTAssertNotNil(assets.first?.image)
    }

    func test_fromUIImages_everyAssetHasUniqueID() {
        let images = Array(repeating: UIImage(systemName: "star")!, count: 5)
        let ids = PhotoAsset.from(uiImages: images).map(\.id)
        XCTAssertEqual(Set(ids).count, 5)
    }

    // MARK: - deinit thread safety

    // Verifies that rapidly allocating and deallocating PhotoAsset (which previously
    // called PHImageManager in deinit from an arbitrary thread) does not crash.
    func test_deinit_doesNotCrash_underRapidAllocationAndDeallocation() {
        for _ in 0..<50 {
            autoreleasepool {
                let url = URL(string: "https://example.com/rapid-\(UUID()).jpg")!
                let asset = PhotoAsset(imageURL: url)
                asset.loadFullImage { _ in }
                // asset deallocates here — deinit must not touch PHImageManager
            }
        }
        // Reaching this point without crashing or triggering thread-checker = pass
    }

    // MARK: - cancelPendingLoad after deinit path

    // Verifies cancelPendingLoad is a safe no-op at every lifecycle stage.
    func test_cancelPendingLoad_isAlwaysSafe() {
        // Before any load
        let asset1 = PhotoAsset(imageURL: URL(string: "https://example.com/a.jpg")!)
        asset1.cancelPendingLoad()

        // During a load
        let asset2 = PhotoAsset(imageURL: URL(string: "https://example.com/b.jpg")!)
        asset2.loadFullImage { _ in }
        asset2.cancelPendingLoad()

        // After cancel — second cancel must be a no-op
        asset2.cancelPendingLoad()

        // With a UIImage asset (no pending requests)
        let asset3 = PhotoAsset(image: UIImage(systemName: "star")!)
        asset3.cancelPendingLoad()
    }

    // MARK: - Caption

    func test_caption_uiImageInit_defaultIsNil() {
        let asset = PhotoAsset(image: UIImage(systemName: "photo")!)
        XCTAssertNil(asset.caption, "Default caption must be nil")
    }

    func test_caption_uiImageInit_customValue() {
        let asset = PhotoAsset(image: UIImage(systemName: "photo")!, caption: "Sunset")
        XCTAssertEqual(asset.caption, "Sunset")
    }

    func test_caption_urlInit_defaultIsNil() {
        let asset = PhotoAsset(imageURL: URL(string: "https://example.com/a.jpg")!)
        XCTAssertNil(asset.caption)
    }

    func test_caption_urlInit_customValue() {
        let asset = PhotoAsset(imageURL: URL(string: "https://example.com/a.jpg")!, caption: "Mountain view")
        XCTAssertEqual(asset.caption, "Mountain view")
    }

    func test_caption_emptyString_isStored() {
        let asset = PhotoAsset(image: UIImage(systemName: "photo")!, caption: "")
        XCTAssertEqual(asset.caption, "")
    }

    // MARK: - loadError

    func test_loadError_initiallyNil() {
        let asset = PhotoAsset(imageURL: URL(string: "https://example.com/photo.jpg")!)
        XCTAssertNil(asset.loadError, "loadError must be nil before any load attempt")
    }

    func test_loadError_imageInit_isNil() {
        // Assets created from a UIImage never perform network loads,
        // so loadError must always remain nil.
        let asset = PhotoAsset(image: UIImage(systemName: "star")!)
        XCTAssertNil(asset.loadError, "UIImage-backed assets must never set loadError")
    }

    func test_loadError_setOnNetworkFailure() async {
        // A clearly invalid URL causes URLSession to fail immediately.
        let asset = PhotoAsset(imageURL: URL(string: "https://localhost:1/nonexistent.jpg")!)
        await withCheckedContinuation { continuation in
            asset.loadFullImage { _ in
                continuation.resume()
            }
        }
        XCTAssertNotNil(asset.loadError,
                        "loadError must be non-nil after a network failure")
    }

    func test_loadError_clearedOnNewLoad() async {
        // Verify that starting a new load resets any previously stored error.
        let asset = PhotoAsset(imageURL: URL(string: "https://localhost:1/nonexistent.jpg")!)
        await withCheckedContinuation { continuation in
            asset.loadFullImage { _ in continuation.resume() }
        }
        XCTAssertNotNil(asset.loadError, "Pre-condition: error must be set after failure")

        // Start a second load — loadError should be cleared immediately.
        asset.loadFullImage { _ in }
        XCTAssertNil(asset.loadError,
                     "loadError must be cleared to nil when a new load starts")
    }
}
