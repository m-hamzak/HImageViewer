//
//  ReorderTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//
//  Tests verify that HImageViewerViewModel.reorderItems(from:to:) correctly
//  moves items in both legacy and media modes, preserves item identity,
//  guards against invalid indices, and clears stale selection indices.
//

import XCTest
@testable import HImageViewer

@MainActor
final class ReorderTests: XCTestCase {

    // MARK: - Helpers

    private func makeAssets(_ count: Int) -> [PhotoAsset] {
        (0..<count).map { _ in PhotoAsset(image: UIImage(systemName: "star")!) }
    }

    private func makeMediaAssets(_ count: Int) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    private func makeVM(assets: [PhotoAsset]) -> HImageViewerViewModel {
        HImageViewerViewModel(assets: assets, usesMediaMode: false)
    }

    private func makeMediaVM(mediaAssets: [MediaAsset]) -> HImageViewerViewModel {
        HImageViewerViewModel(mediaAssets: mediaAssets, usesMediaMode: true)
    }

    // MARK: - Legacy mode: forward moves

    func test_reorderItems_legacy_movesForward() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)               // [A, B, C]
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 0, to: 2)          // → [B, C, A]

        XCTAssertEqual(vm.assets[0].id, ids[1])
        XCTAssertEqual(vm.assets[1].id, ids[2])
        XCTAssertEqual(vm.assets[2].id, ids[0])
    }

    func test_reorderItems_legacy_adjacentForward() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)               // [A, B, C]
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 0, to: 1)          // → [B, A, C]

        XCTAssertEqual(vm.assets[0].id, ids[1])
        XCTAssertEqual(vm.assets[1].id, ids[0])
        XCTAssertEqual(vm.assets[2].id, ids[2])
    }

    // MARK: - Legacy mode: backward moves

    func test_reorderItems_legacy_movesBackward() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)               // [A, B, C]
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 2, to: 0)          // → [C, A, B]

        XCTAssertEqual(vm.assets[0].id, ids[2])
        XCTAssertEqual(vm.assets[1].id, ids[0])
        XCTAssertEqual(vm.assets[2].id, ids[1])
    }

    func test_reorderItems_legacy_adjacentBackward() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)               // [A, B, C]
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 1, to: 0)          // → [B, A, C]

        XCTAssertEqual(vm.assets[0].id, ids[1])
        XCTAssertEqual(vm.assets[1].id, ids[0])
        XCTAssertEqual(vm.assets[2].id, ids[2])
    }

    // MARK: - Legacy mode: two-item swap

    func test_reorderItems_twoItems_swap() {
        let assets = makeAssets(2)
        let ids = assets.map(\.id)               // [A, B]
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 0, to: 1)          // → [B, A]

        XCTAssertEqual(vm.assets[0].id, ids[1])
        XCTAssertEqual(vm.assets[1].id, ids[0])
    }

    // MARK: - No-ops

    func test_reorderItems_sameIndex_noChange() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 1, to: 1)

        XCTAssertEqual(vm.assets.map(\.id), ids, "Same-index reorder must be a no-op")
    }

    func test_reorderItems_fromOutOfBounds_noChange() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 5, to: 0)

        XCTAssertEqual(vm.assets.map(\.id), ids, "Out-of-bounds from index must be ignored")
    }

    func test_reorderItems_toOutOfBounds_noChange() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 0, to: 5)

        XCTAssertEqual(vm.assets.map(\.id), ids, "Out-of-bounds to index must be ignored")
    }

    func test_reorderItems_negativeFrom_noChange() {
        let assets = makeAssets(3)
        let ids = assets.map(\.id)
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: -1, to: 2)

        XCTAssertEqual(vm.assets.map(\.id), ids)
    }

    // MARK: - Selection cleared after reorder

    func test_reorderItems_clearsSelectedIndices() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectedIndices = [0, 2]

        vm.reorderItems(from: 0, to: 2)

        XCTAssertTrue(vm.selectedIndices.isEmpty,
                      "selectedIndices must be cleared after reorder to prevent stale index references")
    }

    func test_reorderItems_sameIndex_doesNotClearSelection() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectedIndices = [1]

        vm.reorderItems(from: 1, to: 1)   // no-op

        XCTAssertFalse(vm.selectedIndices.isEmpty,
                       "No-op reorder (same index) must not clear selection")
    }

    // MARK: - Media mode

    func test_reorderItems_mediaMode_movesForward() {
        let items = makeMediaAssets(3)
        let ids = items.map(\.id)                // [A, B, C]
        let vm = makeMediaVM(mediaAssets: items)

        vm.reorderItems(from: 0, to: 2)          // → [B, C, A]

        XCTAssertEqual(vm.mediaAssets[0].id, ids[1])
        XCTAssertEqual(vm.mediaAssets[1].id, ids[2])
        XCTAssertEqual(vm.mediaAssets[2].id, ids[0])
    }

    func test_reorderItems_mediaMode_clearsSelection() {
        let vm = makeMediaVM(mediaAssets: makeMediaAssets(3))
        vm.selectedIndices = [0, 1]

        vm.reorderItems(from: 0, to: 2)

        XCTAssertTrue(vm.selectedIndices.isEmpty)
    }

    // MARK: - Mode isolation

    func test_reorderItems_legacyMode_doesNotTouchMediaAssets() {
        let vm = HImageViewerViewModel(
            assets: makeAssets(3),
            mediaAssets: makeMediaAssets(3),
            usesMediaMode: false
        )
        let mediaIDs = vm.mediaAssets.map(\.id)

        vm.reorderItems(from: 0, to: 2)

        XCTAssertEqual(vm.mediaAssets.map(\.id), mediaIDs,
                       "Reordering in legacy mode must not touch mediaAssets")
    }

    func test_reorderItems_mediaMode_doesNotTouchAssets() {
        let vm = HImageViewerViewModel(
            assets: makeAssets(3),
            mediaAssets: makeMediaAssets(3),
            usesMediaMode: true
        )
        let assetIDs = vm.assets.map(\.id)

        vm.reorderItems(from: 0, to: 2)

        XCTAssertEqual(vm.assets.map(\.id), assetIDs,
                       "Reordering in media mode must not touch assets")
    }

    // MARK: - Item identity preserved

    func test_reorderItems_preservesItemCount() {
        let vm = makeVM(assets: makeAssets(5))
        vm.reorderItems(from: 0, to: 4)
        XCTAssertEqual(vm.assets.count, 5, "Reorder must not add or remove items")
    }

    func test_reorderItems_preservesAllIDs() {
        let assets = makeAssets(4)
        let allIDs = Set(assets.map(\.id))
        let vm = makeVM(assets: assets)

        vm.reorderItems(from: 0, to: 3)

        XCTAssertEqual(Set(vm.assets.map(\.id)), allIDs,
                       "All original item IDs must still be present after reorder")
    }
}
