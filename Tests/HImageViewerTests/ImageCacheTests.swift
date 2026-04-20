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
}
