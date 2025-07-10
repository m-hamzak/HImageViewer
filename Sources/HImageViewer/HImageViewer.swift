//
//  ImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import AVFoundation

public struct HImageViewer: View {

    @Binding private var assets: [PhotoAsset]
    @Binding private var selectedVideo: URL?

    @State private var selectionMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    @State private var comment: String
    @State private var showEditOptions: Bool = false
    @State private var selectedImages: Set<Int> = []

    @Environment(\.dismiss) private var dismiss
    
    private let config: HImageViewerConfiguration
    private weak var delegate: ImageViewerDelegate?
    
    private var isSinglePhotoMode: Bool {
        assets.count == 1
    }

    public struct Configuration {
        public let title: String?
        public let showCommentBox: Bool
        public let showSaveButton: Bool
        
        public init(
            title: String? = nil,
            showCommentBox: Bool = true,
            showSaveButton: Bool = true
        ) {
            self.title = title
            self.showCommentBox = showCommentBox
            self.showSaveButton = showSaveButton
        }
    }

    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._assets = assets
        self._selectedVideo = selectedVideo
        self.config = configuration
        self._comment = State(initialValue: config.showCommentBox ? (config.title ?? "") : "")
        self.delegate = configuration.delegate
    }

    public var body: some View {
        VStack {
            
//            TopBar
//                .padding(.horizontal)
//                .padding(.top, 12)
           TopBar(config: TopBarConfig (
                isSinglePhotoMode: isSinglePhotoMode,
                selectionMode: selectionMode,
                onDismiss: { dismiss(); delegate?.didTapCloseButton() },
                onSelectToggle: { selectionMode.toggle() },
                onEdit: { delegate?.didTapEditButton() }
            ))
            
            if isSinglePhotoMode {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                        .padding()
                } else if let firstAsset = assets.first {
                    PhotoView(photo: firstAsset, isSinglePhotoMode: true)
                        .padding()
                }
            } else {
                MultiPhotoGrid (
                    assets: assets,
                    selectedIndices: selectedIndices,
                    selectionMode: selectionMode,
                    onSelectToggle: handleSelection
                )
                Spacer()
            }

            BottomBar(comment: $comment, config: BottomBarConfig(
                 isSinglePhotoMode: isSinglePhotoMode,
                 selectionMode: selectionMode,
                 showSaveButton: config.showSaveButton,
                 showCommentBox: config.showCommentBox,
                 title: config.title,
                 onSave: { handleSave() },
                 onDelete: { handleDelete() }
             ))
                
        }
//        .onDisappear {
//            delegate?.didAddPhotos(assets)
//        }
    }
    
    // MARK: - Selection Handling

    private func handleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    // MARK: - Delete Handling

    private func handleDelete() {
        let deletedAssets = selectedIndices.map { assets[$0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }
        selectedIndices.removeAll()
//        delegate?.didDeletePhotos(deletedAssets)
        selectionMode = false
    }

    // MARK: - Save Handling

    private func handleSave() {
        delegate?.didTapSaveButton(comment: comment, photos: assets)
    }
}


 
#Preview {
    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!)]
    @State  var selectedVideo: URL? = nil
    
    HImageViewer(
        assets: $photoAssets,
        selectedVideo: $selectedVideo
    )
}

#Preview {
    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!)]
    @State  var selectedVideo: URL? = nil

    HImageViewer(
        assets: $photoAssets,
        selectedVideo: $selectedVideo
    )
}

