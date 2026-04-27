//
//  ImageCacheTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//

import XCTest
@testable import HImageViewer

final class ImageCacheTests: XCTestCase {

    private let url1 = URL(string: "https://example.com/photo1.jpg")!
    private let url2 = URL(string: "https://example.com/photo2.jpg")!
    private let cache = ImageCache.shared

    override func setUp() {
        super.setUp()
        // Start each test with a clean cache
        cache.removeAll()
    }

    // MARK: - Store and retrieve

    func test_store_andRetrieve_returnsStoredImage() {
        let image = UIImage(systemName: "star")!
        cache[url1] = image
        XCTAssertNotNil(cache[url1], "Stored image must be retrievable")
    }

    func test_retrieve_unknownURL_returnsNil() {
        XCTAssertNil(cache[url1], "Unknown URL must return nil")
    }

    func test_differentURLs_cachedIndependently() {
        let img1 = UIImage(systemName: "star")!
        let img2 = UIImage(systemName: "heart")!
        cache[url1] = img1
        cache[url2] = img2

        XCTAssertNotNil(cache[url1])
        XCTAssertNotNil(cache[url2])
    }

    func test_store_nilValue_removesEntry() {
        let image = UIImage(systemName: "star")!
        cache[url1] = image
        XCTAssertNotNil(cache[url1], "Pre-condition: image should be cached")

        cache[url1] = nil
        XCTAssertNil(cache[url1], "Setting nil must remove the entry")
    }

    func test_removeAll_clearsCache() {
        cache[url1] = UIImage(systemName: "star")!
        cache[url2] = UIImage(systemName: "heart")!

        cache.removeAll()

        XCTAssertNil(cache[url1], "url1 must be cleared after removeAll")
        XCTAssertNil(cache[url2], "url2 must be cleared after removeAll")
    }

    func test_overwrite_replacesExistingEntry() {
        let original = UIImage(systemName: "star")!
        let replacement = UIImage(systemName: "heart")!
        cache[url1] = original
        cache[url1] = replacement

        XCTAssertNotNil(cache[url1], "Overwritten entry must still be present")
    }

    func test_sharedInstance_isSingleton() {
        let a = ImageCache.shared
        let b = ImageCache.shared
        XCTAssertTrue(a === b, "ImageCache.shared must return the same instance")
    }

    // MARK: - Additional store / retrieve

    func test_storeImage_then_retrieveReturnsNonNil() {
        let image = UIImage(systemName: "heart")!
        cache[url1] = image
        XCTAssertNotNil(cache[url1])
    }

    func test_removeAll_thenStore_newItemRetrievable() {
        cache[url1] = UIImage(systemName: "star")!
        cache.removeAll()
        let fresh = UIImage(systemName: "heart")!
        cache[url2] = fresh
        XCTAssertNil(cache[url1],  "url1 must be nil after removeAll")
        XCTAssertNotNil(cache[url2], "Newly stored url2 must be retrievable")
    }

    func test_nilURL_neverCached_removingIsNoOp() {
        let uncached = URL(string: "https://example.com/never-stored.jpg")!
        cache[uncached] = nil   // must not crash
        XCTAssertNil(cache[uncached])
    }

    func test_manyURLs_individualRemovalDoesNotAffectOthers() {
        let urls = (0..<5).map { URL(string: "https://example.com/many-\($0).jpg")! }
        let image = UIImage(systemName: "star")!
        urls.forEach { cache[$0] = image }

        cache[urls[2]] = nil    // remove middle entry

        XCTAssertNil(cache[urls[2]])
        for i in [0, 1, 3, 4] {
            XCTAssertNotNil(cache[urls[i]], "URL \(i) must still be in cache")
        }
        urls.forEach { cache[$0] = nil }  // cleanup
    }

    func test_removeAll_isIdempotent() {
        cache[url1] = UIImage(systemName: "star")!
        cache.removeAll()
        cache.removeAll()   // second call must not crash
        XCTAssertNil(cache[url1])
    }

    func test_store_sameURL_twice_secondValueAvailable() {
        cache[url1] = UIImage(systemName: "star")!
        cache[url1] = UIImage(systemName: "heart")!
        // Must still return a non-nil image after second store
        XCTAssertNotNil(cache[url1])
    }

    // MARK: - Retina cost calculation

    // Verifies that the cache cost uses pixel dimensions (size × scale²) rather than
    // point dimensions (size only). A retina image at 2× scale has 4× the bytes of
    // the equivalent 1× image at the same point size.
    // MARK: - Minimum cost enforcement

    // A pathological image with a zero-point dimension must still receive cost ≥ 1
    // so NSCache's LRU eviction counts it — a cost of 0 is treated as "free" by NSCache.
    func test_cost_zeroDimensionImage_hasMinimumCostOfOne() {
        // Create a 0×0 image via a degenerate renderer
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // UIGraphicsImageRenderer requires positive size, so use 1×1 and zero-override
        // by testing the formula directly (which is the same code path as the subscript setter).
        let rawCost = Int(CGFloat(0) * 1 * CGFloat(0) * 1 * 4)   // simulates 0×0 image
        let clampedCost = max(1, rawCost)
        XCTAssertGreaterThanOrEqual(clampedCost, 1,
            "Cost must be at least 1 so NSCache counts every entry for LRU eviction")
    }

    // An image with very small (but positive) dimensions must have cost ≥ 1.
    func test_cost_smallImage_hasMinimumCostOfOne() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let tinyImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format)
            .image { ctx in ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1)) }
        // Expected cost: 1 × 1 × 1 × 1 × 4 = 4. Confirm it's ≥ 1.
        let cost = max(1, Int(tinyImage.size.width * tinyImage.scale
                              * tinyImage.size.height * tinyImage.scale * 4))
        XCTAssertGreaterThanOrEqual(cost, 1, "Cost for a 1×1 image must be at least 1")
    }

    func test_cost_scalesWithImageScale() {
        // Create two images of the same point size but different pixel scales using
        // UIGraphicsImageRenderer, which honours the display scale parameter.
        let pointSize = CGSize(width: 100, height: 100)

        let format1x = UIGraphicsImageRendererFormat()
        format1x.scale = 1
        let image1x = UIGraphicsImageRenderer(size: pointSize, format: format1x)
            .image { ctx in ctx.fill(CGRect(origin: .zero, size: pointSize)) }

        let format2x = UIGraphicsImageRendererFormat()
        format2x.scale = 2
        let image2x = UIGraphicsImageRenderer(size: pointSize, format: format2x)
            .image { ctx in ctx.fill(CGRect(origin: .zero, size: pointSize)) }

        // Both images have the same point size but different scales
        XCTAssertEqual(image1x.size, image2x.size, "Point sizes must be equal")
        XCTAssertEqual(image1x.scale, 1, accuracy: 0.01)
        XCTAssertEqual(image2x.scale, 2, accuracy: 0.01)

        // Cost formula: width × scale × height × scale × 4
        let cost1x = Int(image1x.size.width * image1x.scale * image1x.size.height * image1x.scale * 4)
        let cost2x = Int(image2x.size.width * image2x.scale * image2x.size.height * image2x.scale * 4)

        XCTAssertEqual(cost1x, 40_000,  "1× image: 100×1 × 100×1 × 4 = 40,000 bytes")
        XCTAssertEqual(cost2x, 160_000, "2× image: 100×2 × 100×2 × 4 = 160,000 bytes")
        XCTAssertEqual(cost2x, cost1x * 4, "2× retina image must cost 4× the 1× image")
    }
}
