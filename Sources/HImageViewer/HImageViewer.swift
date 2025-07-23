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
    @State private var wasImageEdited = false

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var uploadState: HImageViewerUploadState
    
    private let config: HImageViewerConfiguration
    private weak var delegate: HImageViewerControlDelegate?
    
    private var isSinglePhotoMode: Bool {
        assets.count == 1
    }
    private var isUploading: Bool {
        (uploadState.progress ?? 0) > 0 && (uploadState.progress ?? 0) < 1.0
    }
    var shouldShowSaveButton: Bool {
        if isSinglePhotoMode {
            return wasImageEdited || config.showSaveButton
        } else {
            return config.showSaveButton
        }
    }

    public struct Configuration {
        public let title: String?
        public let showCommentBox: Bool
        public let showSaveButton: Bool
        public let showEditButton: Bool
        
        public init(
            title: String? = nil,
            showCommentBox: Bool = false,
            showSaveButton: Bool = false,
            showEditButton: Bool = false
        ) {
            self.title = title
            self.showCommentBox = showCommentBox
            self.showSaveButton = showSaveButton
            self.showEditButton = showEditButton
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
        if let provided = config.uploadState {
                uploadState = provided
            } else {
                uploadState = HImageViewerUploadState()
            }
    }

    public var body: some View {
        ZStack {
            mainComponent
            .onAppear {
                        if uploadState.progress == 1.0 {
                            uploadState.progress = nil
                        }
                    }
            .disabled(uploadState.progress ?? 0 > 0)
            
                if let progress = uploadState.progress {
                VStack {
                    Spacer()
                        ProgressRingOverlayView(progress: progress, title: "Uploading")
                            .padding()
                            .opacity(progress < 1.0 ? 1 : 0)
                                    .animation(.easeOut(duration: 0.3), value: progress)
                                    .onChange(of: progress) { newProgress in
                                                guard newProgress >= 1 else { return }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        dismiss()
                                                    }
                                            }
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }
    
    private var mainComponent: some View {
        VStack {

            TopBar(config: TopBarConfig (
                isSinglePhotoMode: isSinglePhotoMode,
                showEditButton: config.showEditButton,
                selectionMode: selectionMode,
                onDismiss: { dismiss(); delegate?.didTapCloseButton() },
                onSelectToggle: { selectionMode.toggle() },
                onEdit: { delegate?.didTapEditButton(photo: assets.first!) }
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
                showSaveButton: shouldShowSaveButton,
                showCommentBox: config.showCommentBox,
                title: config.title,
                onSave: { handleSave() },
                onDelete: { handleDelete() }
            ))
            
        }
        .onChange(of: assets.first?.image) { _ in
           if isSinglePhotoMode {
                wasImageEdited = true
            }
        }
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

