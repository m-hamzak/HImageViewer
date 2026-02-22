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

    func test_loadThumbnail_withNoPhAssetAndNoImage_returnsNil() {
        let asset = PhotoAsset(imageURL: URL(string: "https://example.com/img.jpg")!)

        // Use a sentinel value to distinguish "completion not called" from "completion(nil)"
        var result: UIImage? = UIImage()  // sentinel: non-nil
        asset.loadThumbnail(targetSize: CGSize(width: 100, height: 100)) { image in
            result = image  // should set to nil
        }

        XCTAssertNil(result, "URL-only assets should return nil from loadThumbnail")
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

    func test_loadFullImage_withNoPhAssetAndNoImage_returnsNil() {
        let asset = PhotoAsset(imageURL: URL(string: "https://example.com/img.jpg")!)
        var result: UIImage? = UIImage()  // sentinel

        asset.loadFullImage { image in
            result = image
        }

        XCTAssertNil(result, "URL-only assets should return nil from loadFullImage")
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

        // Convert to a Set — if any IDs are duplicates, the set will be smaller
        let uniqueIDs = Set(assets.map(\.id))
        XCTAssertEqual(uniqueIDs.count, assets.count, "All assets must have unique IDs")
    }
}
