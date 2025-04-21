//
//  VideoPlayerView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//


import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @StateObject private var playerHolder = PlayerHolder()

    var body: some View {
        VideoPlayer(player: playerHolder.player)
            .onAppear {
                if playerHolder.player.currentItem == nil {
                    playerHolder.player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                }
                playerHolder.player.play()
            }
            .onDisappear {
                playerHolder.player.pause()
            }
            .frame(height: 300)
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}
final class PlayerHolder: ObservableObject {
    @Published var player = AVPlayer()
}
