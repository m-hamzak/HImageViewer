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
struct VideoPlayerView: View {

    // MARK: - Properties

    let videoURL: URL
    @StateObject private var playerHolder = PlayerHolder()

    // MARK: - Body

    var body: some View {
        VideoPlayer(player: playerHolder.player)
            .aspectRatio(16 / 9, contentMode: .fit)
            .cornerRadius(12)
            .shadow(radius: 4)
            .onAppear {
                let item = AVPlayerItem(url: videoURL)
                playerHolder.player.replaceCurrentItem(with: item)
                // Seek to beginning but do NOT autoplay — user controls playback.
                playerHolder.player.seek(to: .zero)
            }
            .onDisappear {
                playerHolder.player.pause()
                playerHolder.player.replaceCurrentItem(with: nil)
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
