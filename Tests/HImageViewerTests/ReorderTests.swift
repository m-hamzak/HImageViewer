//
//  ReorderTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//
//  Tests verify that HImageViewerViewModel.reorderItems(from:to:) correctly
//  moves items, preserves item identity, guards against invalid indices,
//  and clears stale selection indices.
//

import XCTest
@testable import HImageViewer

@MainActor
final class ReorderTests: XCTestCase {

    // MARK: - Helpers

    private func makeMediaAssets(_ count: Int) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    private func makeVM(mediaAssets: [MediaAsset]) -> HImageViewerViewModel {
        HImageViewerViewModel(mediaAssets: mediaAssets)
    }

    // MARK: - Forward moves

    func test_reorderItems_movesForward() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)               // [A, B, C]
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 2)         // → [B, C, A]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[2])
        XCTAssertEqual(vm.mediaAssets[2].id, ids[0])
    }

    func test_reorderItems_adjacentForward() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)               // [A, B, C]
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 1)         // → [B, A, C]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[0])
        XCTAssertEqual(vm.mediaAssets[2].id, ids[2])
    }

    // MARK: - Backward moves

    func test_reorderItems_movesBackward() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)               // [A, B, C]
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 2, to: 0)         // → [C, A, B]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[2])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[0])
        XCTAssertEqual(vm.mediaAssets[2].id, ids[1])
    }

    func test_reorderItems_adjacentBackward() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)               // [A, B, C]
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 1, to: 0)         // → [B, A, C]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[0])
        XCTAssertEqual(vm.mediaAssets[2].id, ids[2])
    }

    // MARK: - Two-item swap

    func test_reorderItems_twoItems_swap() {
        let items = makeMediaAssets(2)
        let ids = items.map(\.id)               // [A, B]
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 1)         // → [B, A]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[0])
    }

    // MARK: - No-ops

    func test_reorderItems_sameIndex_noChange() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 1, to: 1)

        XCTAssertEqual(vm.mediaAssets.map(\.id), ids, "Same-index reorder must be a no-op")
    }

    func test_reorderItems_fromOutOfBounds_noChange() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 5, to: 0)

        XCTAssertEqual(vm.mediaAssets.map(\.id), ids, "Out-of-bounds from index must be ignored")
    }

    func test_reorderItems_toOutOfBounds_noChange() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 5)

        XCTAssertEqual(vm.mediaAssets.map(\.id), ids, "Out-of-bounds to index must be ignored")
    }

    func test_reorderItems_negativeFrom_noChange() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: -1, to: 2)

        XCTAssertEqual(vm.mediaAssets.map(\.id), ids)
    }

    // MARK: - Selection cleared after reorder

    func test_reorderItems_clearsSelectedIndices() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectedIndices = [0, 2]

        vm.reorderItems(from: 0, to: 2)

        XCTAssertTrue(vm.selectedIndices.isEmpty,
                      "selectedIndices must be cleared after reorder to prevent stale index references")
    }

    func test_reorderItems_sameIndex_doesNotClearSelection() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectedIndices = [1]

        vm.reorderItems(from: 1, to: 1)   // no-op

        XCTAssertFalse(vm.selectedIndices.isEmpty,
                       "No-op reorder (same index) must not clear selection")
    }

    // MARK: - Item identity preserved

    func test_reorderItems_preservesItemCount() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5))
        vm.reorderItems(from: 0, to: 4)
        XCTAssertEqual(vm.mediaAssets.count, 5, "Reorder must not add or remove items")
    }

    func test_reorderItems_preservesAllIDs() {
        let items = makeMediaAssets(4)
        let allIDs = Set(items.map(\.id))
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 3)

        XCTAssertEqual(Set(vm.mediaAssets.map(\.id)), allIDs,
                       "All original item IDs must still be present after reorder")
    }

    // MARK: - Mixed media (photo + video)

    func test_reorderItems_withVideoItem_movesCorrectly() {
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        let videoURL = URL(string: "https://example.com/v.mp4")!
        let items: [MediaAsset] = [.photo(photo), .video(videoURL)]
        let ids = items.map(\.id)
        let vm = makeVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 1)     // → [video, photo]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[0])
    }
}
