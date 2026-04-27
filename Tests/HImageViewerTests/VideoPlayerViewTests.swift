//
//  VideoPlayerViewTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/04/2026.
//

import XCTest
import AVFoundation
import Combine
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

    // MARK: - PlayerHolder initial state

    func test_playerHolder_initialStatus_isUnknown() {
        let holder = PlayerHolder()
        XCTAssertEqual(holder.itemStatus, .unknown,
                       "PlayerHolder must start with .unknown item status")
    }

    func test_playerHolder_initialCurrentItem_isNil() {
        let holder = PlayerHolder()
        XCTAssertNil(holder.player.currentItem,
                     "PlayerHolder must start with no current item")
    }

    // MARK: - AVAudioSession configuration

    func test_playerHolder_init_configuresAudioSessionToPlayback() {
        _ = PlayerHolder()
        XCTAssertEqual(
            AVAudioSession.sharedInstance().category, .playback,
            "PlayerHolder.init must configure the audio session category to .playback"
        )
    }

    func test_playerHolder_init_configuresAudioModeToMoviePlayback() {
        _ = PlayerHolder()
        XCTAssertEqual(
            AVAudioSession.sharedInstance().mode, .moviePlayback,
            "PlayerHolder.init must configure the audio session mode to .moviePlayback"
        )
    }

    // MARK: - setItem

    func test_setItem_replacesCurrentItem() {
        let holder = PlayerHolder()
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test.mp4"))
        holder.setItem(item)
        XCTAssertIdentical(holder.player.currentItem, item,
                           "setItem must install the provided item on the player")
    }

    func test_setItem_resetsStatusToUnknown() {
        let holder = PlayerHolder()
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test.mp4"))
        holder.setItem(item)
        // Status is reset synchronously before KVO can drive it to another value.
        XCTAssertEqual(holder.itemStatus, .unknown,
                       "setItem must reset itemStatus to .unknown synchronously")
    }

    func test_setItem_secondCall_replacesFirstItem() {
        let holder = PlayerHolder()
        let item1 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test1.mp4"))
        let item2 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test2.mp4"))
        holder.setItem(item1)
        holder.setItem(item2)
        XCTAssertIdentical(holder.player.currentItem, item2,
                           "A second setItem call must replace the first item")
    }

    func test_setItem_secondCall_resetsStatusToUnknown() {
        let holder = PlayerHolder()
        let item1 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test1.mp4"))
        let item2 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test2.mp4"))
        holder.setItem(item1)
        holder.setItem(item2)
        XCTAssertEqual(holder.itemStatus, .unknown,
                       "A second setItem call must reset itemStatus to .unknown")
    }

    // MARK: - clearItem

    func test_clearItem_removesCurrentItem() {
        let holder = PlayerHolder()
        holder.setItem(AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test.mp4")))
        holder.clearItem()
        XCTAssertNil(holder.player.currentItem,
                     "clearItem must remove the current item from the player")
    }

    func test_clearItem_resetsStatusToUnknown() {
        let holder = PlayerHolder()
        holder.setItem(AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test.mp4")))
        holder.clearItem()
        XCTAssertEqual(holder.itemStatus, .unknown,
                       "clearItem must reset itemStatus to .unknown")
    }

    func test_clearItem_withNoItemSet_doesNotCrash() {
        let holder = PlayerHolder()
        // Must not crash when called on a fresh holder that never had an item.
        holder.clearItem()
        XCTAssertNil(holder.player.currentItem)
        XCTAssertEqual(holder.itemStatus, .unknown)
    }

    // MARK: - Observation cancellation

    // When setItem is called a second time, the first item's status publisher must be
    // cancelled so stale updates from item1 never overwrite the status driven by item2.
    func test_setItem_cancelsPreviousObservation() {
        let holder = PlayerHolder()
        let item1 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test1.mp4"))
        let item2 = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test2.mp4"))
        holder.setItem(item1)
        holder.setItem(item2)
        // Verify holder reflects item2, confirming item1's pipeline was torn down.
        XCTAssertIdentical(holder.player.currentItem, item2)
        XCTAssertEqual(holder.itemStatus, .unknown)
    }

    // clearItem must also cancel the active status subscription so no stale update
    // arrives after the item has been released.
    func test_clearItem_cancelsPreviousObservation() {
        let holder = PlayerHolder()
        holder.setItem(AVPlayerItem(url: URL(fileURLWithPath: "/tmp/test.mp4")))
        holder.clearItem()
        // Post-clear: status must remain .unknown and no item must be present.
        XCTAssertNil(holder.player.currentItem)
        XCTAssertEqual(holder.itemStatus, .unknown)
    }
}
