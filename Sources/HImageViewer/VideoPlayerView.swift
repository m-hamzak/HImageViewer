//
//  VideoPlayerView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//


import SwiftUI
import AVKit

public struct VideoPlayerView: View {
    let videoURL: URL
    @StateObject private var playerHolder = PlayerHolder()

    public var body: some View {
        VStack {
            Spacer()
            VideoPlayer(player: playerHolder.player)
                .onAppear {
                    let item = AVPlayerItem(url: videoURL)
                    playerHolder.player.replaceCurrentItem(with: item)
                    playerHolder.player.seek(to: .zero)
                    playerHolder.player.play()
                }
                .onDisappear {
                    playerHolder.player.pause()
                    playerHolder.player.replaceCurrentItem(with: nil)
                }
                .frame(height: 300)
                .cornerRadius(12)
                .shadow(radius: 4)
            Spacer()
        }

    }
}

final class PlayerHolder: ObservableObject {
    @Published var player = AVPlayer()

    deinit {
        player.replaceCurrentItem(with: nil)
    }
}
