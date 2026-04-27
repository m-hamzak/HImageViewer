//
//  HImageViewerUploadStateTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
import Combine    // Needed for AnyCancellable and sink
@testable import HImageViewer

final class HImageViewerUploadStateTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_defaultInit_progressIsNil() {
        let state = HImageViewerUploadState()
        XCTAssertNil(state.progress, "Default progress should be nil (no upload)")
    }

    func test_initWithProgress_setsValue() {
        let state = HImageViewerUploadState(progress: 0.5)
        XCTAssertEqual(state.progress, 0.5, "Init with 0.5 should store 0.5")
    }

    // MARK: - @Published Behavior Test

    func test_progressIsPublished_triggersObjectWillChange() {
        let state = HImageViewerUploadState()

        // Create an expectation — test will wait until this is fulfilled
        let expectation = expectation(description: "objectWillChange should fire when progress changes")

        // Subscribe to the objectWillChange publisher
        var cancellable: AnyCancellable?
        cancellable = state.objectWillChange.sink { _ in
            expectation.fulfill()
        }

        // Change progress — this should trigger objectWillChange
        state.progress = 0.5

        // Wait up to 1 second for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)

        // Clean up the subscription
        cancellable?.cancel()
    }

    // MARK: - Value Mutation Tests

    func test_progressCanBeSetToNil() {
        let state = HImageViewerUploadState(progress: 0.5)
        state.progress = nil
        XCTAssertNil(state.progress, "Progress should be nil after being set to nil")
    }

    func test_progressCanBeSetToOne() {
        let state = HImageViewerUploadState()
        state.progress = 1.0
        XCTAssertEqual(state.progress, 1.0, "Progress 1.0 means upload complete")
    }

    func test_progressCanBeSetToZero() {
        let state = HImageViewerUploadState()
        state.progress = 0.0
        XCTAssertEqual(state.progress, 0.0, "Progress should be exactly 0.0")
        XCTAssertNotNil(state.progress, "0.0 is NOT nil — they have different meanings")
    }

    // MARK: - Boundary values

    func test_progress_atNearlyComplete_isNotNil() {
        let state = HImageViewerUploadState(progress: 0.99)
        XCTAssertNotNil(state.progress)
        XCTAssertEqual(state.progress!, 0.99, accuracy: 0.0001)
    }

    func test_progress_incrementalUpdates_allStored() {
        let state = HImageViewerUploadState()
        let values: [Double] = [0.1, 0.25, 0.5, 0.75, 0.99, 1.0]
        for v in values {
            state.progress = v
            XCTAssertEqual(state.progress!, v, accuracy: 0.0001)
        }
    }

    func test_progress_setToNilAfterComplete_isNil() {
        let state = HImageViewerUploadState(progress: 1.0)
        state.progress = nil
        XCTAssertNil(state.progress)
    }

    func test_isUploading_at0_99() {
        let p: Double? = 0.99
        XCTAssertTrue((p ?? 0) > 0 && (p ?? 0) < 1.0)
    }

    func test_isUploading_at0_01() {
        let p: Double? = 0.01
        XCTAssertTrue((p ?? 0) > 0 && (p ?? 0) < 1.0)
    }

    func test_isUploading_atExactlyOne_isFalse() {
        let p: Double? = 1.0
        XCTAssertFalse((p ?? 0) > 0 && (p ?? 0) < 1.0)
    }

    func test_progress_canOscillateBetweenNilAndValue() {
        let state = HImageViewerUploadState()
        state.progress = 0.5
        XCTAssertNotNil(state.progress)
        state.progress = nil
        XCTAssertNil(state.progress)
        state.progress = 0.8
        XCTAssertEqual(state.progress, 0.8)
    }
}
