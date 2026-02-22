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
}
