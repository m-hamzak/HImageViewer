//
//  HapticFeedbackTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//
//  Tests verify that the ViewModel fires the correct haptic style for every
//  user action. A MockHapticFeedbackProvider spy is injected so no real
//  hardware is touched.
//

import XCTest
import UIKit
@testable import HImageViewer

// MARK: - Spy

/// Records every `impact(_:)` call for test assertions.
final class MockHapticFeedbackProvider: HapticFeedbackProviding {
    private(set) var impactCallCount: Int = 0
    private(set) var recordedStyles: [UIImpactFeedbackGenerator.FeedbackStyle] = []

    var lastStyle: UIImpactFeedbackGenerator.FeedbackStyle? { recordedStyles.last }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        impactCallCount += 1
        recordedStyles.append(style)
    }

    func reset() {
        impactCallCount = 0
        recordedStyles.removeAll()
    }
}

// MARK: - Tests

@MainActor
final class HapticFeedbackTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(
        assets: [PhotoAsset] = [],
        mediaAssets: [MediaAsset] = [],
        usesMediaMode: Bool = false
    ) -> (HImageViewerViewModel, MockHapticFeedbackProvider) {
        let mock = MockHapticFeedbackProvider()
        let vm = HImageViewerViewModel(
            assets: assets,
            mediaAssets: mediaAssets,
            usesMediaMode: usesMediaMode,
            haptics: mock
        )
        return (vm, mock)
    }

    private func makeAssets(_ n: Int) -> [PhotoAsset] {
        (0..<n).map { _ in PhotoAsset(image: UIImage(systemName: "star")!) }
    }

    private func makeMediaAssets(_ n: Int) -> [MediaAsset] {
        (0..<n).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    // MARK: - handleSelection

    func test_handleSelection_select_triggersMediumImpact() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.handleSelection(0)
        XCTAssertEqual(mock.lastStyle, .medium)
    }

    func test_handleSelection_deselect_triggersMediumImpact() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.handleSelection(0)   // select
        mock.reset()
        vm.handleSelection(0)   // deselect
        XCTAssertEqual(mock.lastStyle, .medium,
                       "Deselection must also fire medium impact")
    }

    func test_handleSelection_calledExactlyOnce() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.handleSelection(1)
        XCTAssertEqual(mock.impactCallCount, 1)
    }

    func test_handleSelection_multipleTaps_callCountMatches() {
        let (vm, mock) = makeVM(assets: makeAssets(5))
        vm.handleSelection(0)
        vm.handleSelection(1)
        vm.handleSelection(2)
        XCTAssertEqual(mock.impactCallCount, 3)
    }

    // MARK: - cancelSelection

    func test_cancelSelection_triggersLightImpact() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0, 1]
        vm.cancelSelection()
        XCTAssertEqual(mock.lastStyle, .light)
    }

    func test_cancelSelection_whenNothingSelected_stillFires() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.cancelSelection()
        XCTAssertEqual(mock.impactCallCount, 1,
                       "cancelSelection always fires, even with empty selection")
        XCTAssertEqual(mock.lastStyle, .light)
    }

    // MARK: - handleDelete

    func test_handleDelete_triggersHeavyImpact() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertEqual(mock.lastStyle, .heavy)
    }

    func test_handleDelete_calledExactlyOnce() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.selectedIndices = [0, 1]
        vm.handleDelete()
        XCTAssertEqual(mock.impactCallCount, 1)
    }

    func test_handleDelete_mediaMode_triggersHeavyImpact() {
        let (vm, mock) = makeVM(mediaAssets: makeMediaAssets(3), usesMediaMode: true)
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertEqual(mock.lastStyle, .heavy)
    }

    func test_handleDelete_emptySelection_doesNotFire() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        // selectedIndices is empty by default
        vm.handleDelete()
        XCTAssertEqual(mock.impactCallCount, 0,
                       "No haptic should fire when there is nothing to delete")
    }

    // MARK: - handleSave

    func test_handleSave_triggersMediumImpact() {
        let (vm, mock) = makeVM(assets: makeAssets(1))
        vm.handleSave()
        XCTAssertEqual(mock.lastStyle, .medium)
    }

    func test_handleSave_calledExactlyOnce() {
        let (vm, mock) = makeVM(assets: makeAssets(1))
        vm.handleSave()
        XCTAssertEqual(mock.impactCallCount, 1)
    }

    // MARK: - Mock provider behaviour

    func test_mockProvider_recordsAllStyles() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.handleSelection(0)   // medium
        vm.cancelSelection()    // light
        vm.selectedIndices = [0]
        vm.handleDelete()       // heavy
        XCTAssertEqual(mock.recordedStyles, [.medium, .light, .heavy])
    }

    func test_mockProvider_reset_clearsState() {
        let (vm, mock) = makeVM(assets: makeAssets(3))
        vm.handleSelection(0)
        mock.reset()
        XCTAssertEqual(mock.impactCallCount, 0)
        XCTAssertNil(mock.lastStyle)
    }

    // MARK: - Default provider type

    func test_vmDefaultHaptics_isRealProvider() {
        let vm = HImageViewerViewModel(usesMediaMode: false)
        XCTAssertTrue(vm.haptics is HapticFeedbackProvider,
                      "Default haptics must be the real HapticFeedbackProvider")
    }
}
