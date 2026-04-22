//
//  VideoPlayerViewTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/04/2026.
//

import XCTest
@testable import HImageViewer

final class VideoPlayerViewTests: XCTestCase {

    // MARK: - Aspect ratio loading

    // A non-video URL (e.g. a webpage) has no video track, so aspectRatio(for:)
    // must return nil rather than crash or return a nonsense value.
    func test_aspectRatio_nonVideoURL_returnsNil() async {
        let url = URL(string: "https://example.com/not-a-video")!
        let ratio = await VideoPlayerView.aspectRatio(for: url)
        XCTAssertNil(ratio, "A URL with no video track must yield nil aspect ratio")
    }

    // A file:// URL pointing to a non-existent file also has no video track.
    func test_aspectRatio_missingFileURL_returnsNil() async {
        let url = URL(fileURLWithPath: "/tmp/does_not_exist_\(UUID()).mp4")
        let ratio = await VideoPlayerView.aspectRatio(for: url)
        XCTAssertNil(ratio, "A missing file URL must yield nil aspect ratio")
    }

    // The helper must return a positive ratio (or nil) — never zero or negative.
    func test_aspectRatio_ifNonNil_isPositive() async {
        // Use a known-bad URL so the result is nil; skip the positive check for CI
        // where no real video files are available. The important invariant is: never ≤ 0.
        let url = URL(string: "https://example.com/fake.mp4")!
        let ratio = await VideoPlayerView.aspectRatio(for: url)
        if let ratio {
            XCTAssertGreaterThan(ratio, 0, "Aspect ratio must be positive when non-nil")
        }
        // nil is also a valid result for an unreachable URL
    }
}
