//
//  VideoPlayerView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import AVKit

/// A SwiftUI wrapper around `AVKit.VideoPlayer` for use inside `HImageViewer`.
///
/// - The player is **not** started automatically — the viewer shows native AVKit transport controls
///   so the user can start playback with a tap.
/// - Playback is paused and the player item is released when the view disappears, preventing
///   background audio leakage when the user swipes to another page.
/// - The aspect ratio is read from the video track's `naturalSize` and applied dynamically,
///   so portrait, square, and landscape videos all render at their correct proportions.
struct VideoPlayerView: View {

    // MARK: - Properties

    let videoURL: URL
    @StateObject private var playerHolder = PlayerHolder()
    @State private var videoAspectRatio: CGFloat? = nil

    // MARK: - Body

    var body: some View {
        VideoPlayer(player: playerHolder.player)
            .aspectRatio(videoAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 4)
            .accessibilityLabel("Video player")
            .accessibilityHint("Use the controls to play or pause")
            .onAppear {
                // Skip recreation if the player is already configured for this URL
                // (prevents redundant AVPlayerItem allocation on re-appear).
                guard (playerHolder.player.currentItem?.asset as? AVURLAsset)?.url != videoURL else { return }
                let item = AVPlayerItem(url: videoURL)
                playerHolder.player.replaceCurrentItem(with: item)
                playerHolder.player.seek(to: .zero)
                Task { videoAspectRatio = await Self.aspectRatio(for: videoURL) }
            }
            .onDisappear {
                playerHolder.player.pause()
                playerHolder.player.replaceCurrentItem(with: nil)
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
private final class PlayerHolder: ObservableObject {
    let player = AVPlayer()

    deinit {
        player.replaceCurrentItem(with: nil)
    }
}
