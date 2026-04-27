//
//  VideoPlayerView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import AVKit
import Combine

/// A SwiftUI wrapper around `AVKit.VideoPlayer` for use inside `HImageViewer`.
///
/// - The player is **not** started automatically — the viewer shows native AVKit transport controls
///   so the user can start playback with a tap.
/// - Playback is paused and the player item is released when the view disappears, preventing
///   background audio leakage when the user swipes to another page.
/// - The aspect ratio is read from the video track's `naturalSize` and applied dynamically,
///   so portrait, square, and landscape videos all render at their correct proportions.
/// - When the player item enters the `.failed` status, an error overlay with a **Retry** button
///   replaces the native AVKit ⊘ UI, giving the user a clear recovery path.
struct VideoPlayerView: View {

    // MARK: - Properties

    let videoURL: URL
    @StateObject private var playerHolder = PlayerHolder()
    @State private var videoAspectRatio: CGFloat? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            VideoPlayer(player: playerHolder.player)

            if playerHolder.itemStatus == .failed {
                videoErrorOverlay
            }
        }
        .aspectRatio(videoAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 4)
        .accessibilityLabel("Video player")
        .accessibilityHint(
            playerHolder.itemStatus == .failed
                ? "Video failed to load. Activate to retry."
                : "Use the controls to play or pause"
        )
        .onAppear { loadItem() }
        .onDisappear {
            playerHolder.player.pause()
            playerHolder.clearItem()
        }
    }

    // MARK: - Error overlay

    private var videoErrorOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)
                Text("Video unavailable")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.medium))
                Button("Retry", action: loadItem)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Item management

    /// Loads a new `AVPlayerItem` for `videoURL`.
    /// Skips recreation if the same URL is already loaded and healthy.
    /// Always reloads when the previous item has failed (retry path).
    private func loadItem() {
        if let asset = playerHolder.player.currentItem?.asset as? AVURLAsset,
           asset.url.standardized == videoURL.standardized,
           playerHolder.itemStatus != .failed {
            return
        }
        let item = AVPlayerItem(url: videoURL)
        playerHolder.setItem(item)
        playerHolder.player.seek(to: .zero)
        if videoAspectRatio == nil {
            Task { videoAspectRatio = await Self.aspectRatio(for: videoURL) }
        }
    }

    // MARK: - Aspect ratio loading

    /// Reads the video track's natural size from the asset and returns width/height.
    /// Uses `loadValuesAsynchronously` for iOS 15 compatibility.
    /// Returns `nil` while loading or when no video track is found.
    static func aspectRatio(for url: URL) async -> CGFloat? {
        let asset = AVURLAsset(url: url)
        return await withCheckedContinuation { continuation in
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                guard asset.statusOfValue(forKey: "tracks", error: nil) == .loaded,
                      let track = asset.tracks(withMediaType: .video).first else {
                    continuation.resume(returning: nil)
                    return
                }
                // Apply the track's preferred transform to get the display orientation.
                let size = track.naturalSize.applying(track.preferredTransform)
                let w = abs(size.width)
                let h = abs(size.height)
                continuation.resume(returning: h > 0 ? w / h : nil)
            }
        }
    }
}

// MARK: - Player Holder

/// Wraps `AVPlayer` in an `ObservableObject` so SwiftUI manages its lifetime correctly.
///
/// Responsibilities:
/// - Configures `AVAudioSession` to `.playback` / `.moviePlayback` on creation so that video
///   plays through the speaker even when the device is silenced or another app held the session.
/// - Observes the current `AVPlayerItem.status` via Combine and surfaces it as `@Published`
///   `itemStatus` so the view can react to loading, ready, and failure states.
final class PlayerHolder: ObservableObject {

    // MARK: - Properties

    let player = AVPlayer()
    @Published private(set) var itemStatus: AVPlayerItem.Status = .unknown
    private var statusCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            // Non-fatal — AVKit will still render video; audio may be affected in edge cases.
        }
    }

    // MARK: - Item management

    /// Replaces the current player item and begins observing its `status`.
    /// Any previous status observation is cancelled before the new one is set up.
    func setItem(_ item: AVPlayerItem) {
        statusCancellable = nil
        player.replaceCurrentItem(with: item)
        itemStatus = .unknown
        statusCancellable = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.itemStatus = status
            }
    }

    /// Removes the current item and cancels status observation.
    func clearItem() {
        statusCancellable = nil
        player.replaceCurrentItem(with: nil)
        itemStatus = .unknown
    }

    deinit {
        player.replaceCurrentItem(with: nil)
    }
}
