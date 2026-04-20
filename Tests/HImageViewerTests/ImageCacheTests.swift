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
}
