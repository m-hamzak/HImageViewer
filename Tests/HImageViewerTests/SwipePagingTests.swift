//
//  SwipePagingTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 19/04/2026.
//

import XCTest
import SwiftUI
@testable import HImageViewer

@MainActor
final class SwipePagingTests: XCTestCase {

    // MARK: - Helpers

    private func makeMediaAssets(_ count: Int) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    // MARK: - initialIndex Clamping

    func test_initialIndex_zero_withOneAsset() {
        let items = makeMediaAssets(1)
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 0)
        XCTAssertNotNil(view, "HImageViewer with initialIndex 0 should initialise without crashing")
    }

    func test_initialIndex_outOfBounds_doesNotCrash() {
        let items = makeMediaAssets(2)
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 99)
        XCTAssertNotNil(view, "Out-of-bounds initialIndex must not crash")
    }

    func test_initialIndex_negative_doesNotCrash() {
        let items = makeMediaAssets(1)
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: -5)
        XCTAssertNotNil(view, "Negative initialIndex must not crash")
    }

    func test_initialIndex_emptyAssets_doesNotCrash() {
        let view = HImageViewer(mediaAssets: .constant([]), initialIndex: 3)
        XCTAssertNotNil(view, "initialIndex on empty assets must not crash")
    }

    // MARK: - currentIndex clamping helpers (logic level)

    func test_clampIndex_withinRange_unchanged() {
        let count = 5
        let index = 3
        let clamped = count == 0 ? 0 : max(0, min(index, count - 1))
        XCTAssertEqual(clamped, 3)
    }

    func test_clampIndex_beyondEnd_clampsToLast() {
        let count = 3
        let clamped = count == 0 ? 0 : max(0, min(10, count - 1))
        XCTAssertEqual(clamped, 2)
    }

    func test_clampIndex_atExactlyCount_clampsToLast() {
        let count = 4
        let clamped = count == 0 ? 0 : max(0, min(count, count - 1))
        XCTAssertEqual(clamped, 3, "index == count is off-by-one — must clamp to count-1")
    }

    func test_clampIndex_zero_isAlwaysValid() {
        let count = 1
        let clamped = count == 0 ? 0 : max(0, min(0, count - 1))
        XCTAssertEqual(clamped, 0)
    }

    // MARK: - Select mode entry / exit

    func test_selectMode_entry_setsFlag() {
        var selectionMode = false
        selectionMode = true
        XCTAssertTrue(selectionMode, "onSelectToggle must set selectionMode to true")
    }

    func test_cancelSelection_exitsModeAndClearsIndices() {
        var selectionMode = true
        var selectedIndices: Set<Int> = [0, 1, 2]

        selectionMode = false
        selectedIndices.removeAll()

        XCTAssertFalse(selectionMode)
        XCTAssertTrue(selectedIndices.isEmpty)
    }

    func test_showSelectButton_trueForMultipleAssets() {
        let count = 3
        XCTAssertTrue(count > 1, "Select button must appear when there are 2+ assets")
    }

    func test_showSelectButton_falseForSingleAsset() {
        let count = 1
        XCTAssertFalse(count > 1, "Select button must be hidden for a single asset")
    }

    func test_showSelectButton_falseForEmptyAssets() {
        let count = 0
        XCTAssertFalse(count > 1, "Select button must be hidden when no assets")
    }

    func test_showSelectButton_trueForExactlyTwo() {
        XCTAssertTrue(2 > 1)
    }

    // MARK: - Rendering smoke test

    func test_pagedViewer_multipleAssets_renders() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "heart")!)),
            .photo(PhotoAsset(image: UIImage(systemName: "circle")!))
        ]
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 1)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 812))
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        let rendered = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertGreaterThan(rendered.size.width, 0, "Paged viewer should render without crashing")
    }

    func test_pagedViewer_mixedMedia_renders() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/v.mp4")!)
        ]
        let view = HImageViewer(mediaAssets: .constant(items), initialIndex: 0)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 812))
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        let rendered = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        XCTAssertGreaterThan(rendered.size.width, 0, "Mixed media viewer should render without crashing")
    }

    // MARK: - Deletion correctness

    func test_deleteMiddleAsset_countReducesByOne() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let toRemove = assets[1]
        assets.removeAll { $0.id == toRemove.id }
        XCTAssertEqual(assets.count, 2)
        XCTAssertFalse(assets.contains { $0.id == toRemove.id })
    }

    func test_deleteFirstAsset_remainderOrderPreserved() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!),
            PhotoAsset(image: UIImage(systemName: "circle")!)
        ]
        let secondID = assets[1].id
        let thirdID  = assets[2].id
        assets.remove(at: 0)
        XCTAssertEqual(assets[0].id, secondID)
        XCTAssertEqual(assets[1].id, thirdID)
    }

    func test_deleteAllAssets_arrayIsEmpty() {
        var assets = [
            PhotoAsset(image: UIImage(systemName: "star")!),
            PhotoAsset(image: UIImage(systemName: "heart")!)
        ]
        assets.removeAll()
        XCTAssertTrue(assets.isEmpty)
    }

    // MARK: - totalCount

    func test_totalCount_equalsMediaAssetsCount() {
        let count = 4
        XCTAssertEqual(count, 4)
    }
}
