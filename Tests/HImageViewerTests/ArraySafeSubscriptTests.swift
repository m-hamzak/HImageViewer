//
//  ArraySafeSubscriptTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026..
//

import XCTest
@testable import HImageViewer

final class ArraySafeSubscriptTests: XCTestCase {

    // MARK: - Valid Index Tests

    func test_validIndex_returnsElement() {
        let array = [10, 20, 30]
        XCTAssertEqual(array[safe: 1], 20, "Index 1 should return the second element (20)")
    }

    func test_firstIndex_returnsFirst() {
        let array = ["a", "b"]
        XCTAssertEqual(array[safe: 0], "a", "Index 0 should return the first element")
    }

    func test_lastValidIndex_returnsLast() {
        let array = ["a", "b", "c"]
        XCTAssertEqual(array[safe: 2], "c", "Last valid index should return the last element")
    }

    // MARK: - Invalid Index Tests

    func test_negativeIndex_returnsNil() {
        let array = [1, 2, 3]
        XCTAssertNil(array[safe: -1], "Negative index should return nil, not crash")
    }

    func test_indexEqualToCount_returnsNil() {
        let array = [1, 2, 3]
        XCTAssertNil(array[safe: 3], "Index equal to count should return nil (off-by-one protection)")
    }

    func test_indexBeyondCount_returnsNil() {
        let array = [1, 2]
        XCTAssertNil(array[safe: 100], "Far out-of-bounds index should return nil")
    }

    func test_emptyArray_returnsNil() {
        let array: [Int] = []
        XCTAssertNil(array[safe: 0], "Any index on empty array should return nil")
    }

    // MARK: - Real-World Type Test

    @MainActor
    func test_withPhotoAssetArray() {
        // Create test assets (using SF Symbols since they're always available in tests)
        let assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]

        // Valid indices should return the asset
        XCTAssertNotNil(assets[safe: 0], "Index 0 should return first PhotoAsset")
        XCTAssertNotNil(assets[safe: 1], "Index 1 should return second PhotoAsset")

        // Invalid index should return nil (not crash)
        XCTAssertNil(assets[safe: 2], "Index 2 should return nil for 2-element array")
    }
}
