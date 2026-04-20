//
//  HImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

/// A SwiftUI view for displaying and managing photos and videos with editing capabilities.
///
/// `HImageViewer` provides a full-screen paged viewer for displaying photos/videos with support for:
/// - Swipe paging through all photos
/// - Pinch-to-zoom and double-tap zoom on each photo
/// - Multi-photo selection and deletion via grid overlay
/// - Video playback
/// - Optional comment/title display
/// - Upload progress tracking
///
/// ## Usage
///
/// ### Basic viewer:
/// ```swift
/// @State var assets = PhotoAsset.from(uiImages: myImages)
/// @State var selectedVideo: URL? = nil
///
/// HImageViewer(
///     assets: $assets,
///     selectedVideo: $selectedVideo
/// )
/// ```
///
/// ### Open at a specific index:
/// ```swift
/// HImageViewer(
///     assets: $assets,
///     selectedVideo: $selectedVideo,
///     initialIndex: 2
/// )
/// ```
///
/// - Important: The viewer automatically dismisses when all assets are deleted.
/// - Note: For upload progress tracking, pass a shared `HImageViewerUploadState` via configuration.
public struct HImageViewer: View {

    // MARK: - Properties

    @Binding private var assets: [PhotoAsset]
    @Binding private var selectedVideo: URL?

    @State private var currentIndex: Int
    @State private var selectionMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    @State private var comment: String
    @State private var wasImageEdited = false
    @State private var dragOffset: CGFloat = 0

    private let dismissThreshold: CGFloat = 120

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var uploadState: HImageViewerUploadState

    private let config: HImageViewerConfiguration
    private weak var delegate: HImageViewerControlDelegate?

    // MARK: - Computed Properties

    private var isUploading: Bool {
        (uploadState.progress ?? 0) > 0 && (uploadState.progress ?? 0) < 1.0
    }

    private var shouldShowSaveButton: Bool {
        wasImageEdited || config.showSaveButton
    }

    private var currentAsset: PhotoAsset? {
        assets[safe: currentIndex]
    }

    /// `"2 / 5"` when there are multiple assets and not in selection mode; `nil` otherwise.
    private var pageCounterText: String? {
        guard assets.count > 1, !selectionMode else { return nil }
        return "\(currentIndex + 1) / \(assets.count)"
    }

    /// 0→1 progress of the drag towards the dismiss threshold.
    private var dragProgress: Double {
        min(Double(max(0, dragOffset)) / Double(dismissThreshold), 1.0)
    }

    // MARK: - Initialization

    /// Creates a new image viewer instance.
    ///
    /// - Parameters:
    ///   - assets: A binding to the array of `PhotoAsset` objects to display. Modified when photos are deleted.
    ///   - selectedVideo: A binding to an optional video URL. If non-nil, displays video player instead of photos.
    ///   - initialIndex: The index of the photo to display first. Clamped to valid range. Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to standard configuration.
    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._assets = assets
        self._selectedVideo = selectedVideo
        self.config = configuration
        self._comment = State(initialValue: configuration.initialComment ?? "")
        self.delegate = configuration.delegate

        let count = assets.wrappedValue.count
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        self._currentIndex = State(initialValue: clamped)

        if let provided = configuration.uploadState {
            uploadState = provided
        } else {
            uploadState = HImageViewerUploadState()
        }
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            mainComponent
                .offset(y: max(0, dragOffset))
                .opacity(1 - dragProgress * 0.35)
                .gesture(dragToDismissGesture)
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
                        .onChangeCompat(of: progress) { newProgress in
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

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack(spacing: 0) {
            TopBar(config: TopBarConfig(
                showEditButton: config.showEditButton,
                showSelectButton: assets.count > 1,
                selectionMode: selectionMode,
                pageCounterText: pageCounterText,
                onDismiss: { dismiss(); delegate?.didTapCloseButton() },
                onCancelSelection: {
                    selectionMode = false
                    selectedIndices.removeAll()
                },
                onSelectToggle: { selectionMode = true },
                onEdit: {
                    guard let currentAsset else { return }
                    delegate?.didTapEditButton(photo: currentAsset)
                }
            ))

            ZStack {
                contentView
                if selectionMode {
                    MultiPhotoGrid(
                        assets: assets,
                        selectedIndices: selectedIndices,
                        selectionMode: selectionMode,
                        onSelectToggle: handleSelection
                    )
                    .background(Color(UIColor.systemBackground))
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectionMode)

            if !selectionMode {
                PageDotsView(currentIndex: currentIndex, count: assets.count)
            }

            BottomBar(comment: $comment, config: BottomBarConfig(
                selectionMode: selectionMode,
                showSaveButton: shouldShowSaveButton,
                showCommentBox: config.showCommentBox,
                title: config.title,
                onSave: { handleSave() },
                onDelete: { handleDelete() }
            ))
        }
        .onChangeCompat(of: assets[safe: currentIndex]?.image) { _ in
            wasImageEdited = true
        }
        .onChangeCompat(of: assets.count) { newCount in
            if newCount == 0 {
                dismiss()
            } else {
                currentIndex = min(currentIndex, newCount - 1)
            }
        }
        .onChangeCompat(of: selectionMode) { _ in
            // Reset any in-flight drag when entering/exiting selection mode
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dragOffset = 0
            }
        }
    }

    // MARK: - Drag-to-Dismiss Gesture

    private var dragToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !selectionMode, uploadState.progress == nil else { return }
                let translation = value.translation
                // Activate only for predominantly downward drags to avoid
                // conflicting with horizontal TabView paging
                guard translation.height > 0,
                      translation.height > abs(translation.width) * 1.5 else { return }
                dragOffset = translation.height
            }
            .onEnded { value in
                let rawHeight = value.translation.height
                let predictedHeight = value.predictedEndTranslation.height
                let shouldDismiss = rawHeight > dismissThreshold
                    || predictedHeight > dismissThreshold

                if shouldDismiss {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = UIScreen.main.bounds.height
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                        delegate?.didTapCloseButton()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let videoURL = selectedVideo {
            VideoPlayerView(videoURL: videoURL)
                .padding()
        } else if !assets.isEmpty {
            TabView(selection: $currentIndex) {
                ForEach(Array(assets.enumerated()), id: \.1.id) { index, asset in
                    PhotoView(photo: asset, isSinglePhotoMode: true)
                        .padding(.horizontal)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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
        let deletedAssets = selectedIndices
            .filter { $0 < assets.count }
            .compactMap { assets[safe: $0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }
        selectedIndices.removeAll()
        selectionMode = false
        if !assets.isEmpty {
            currentIndex = min(currentIndex, assets.count - 1)
        }
    }

    // MARK: - Save Handling

    private func handleSave() {
        delegate?.didTapSaveButton(comment: comment, photos: assets)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

private struct SinglePhotoPreview: View {
    @State private var assets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!)]
    @State private var selectedVideo: URL? = nil
    var body: some View {
        HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
    }
}

private struct MultiPhotoPreview: View {
    @State private var assets: [PhotoAsset] = (0..<5).map { _ in PhotoAsset(image: UIImage(systemName: "person")!) }
    @State private var selectedVideo: URL? = nil
    var body: some View {
        HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
    }
}

#Preview("Single") { SinglePhotoPreview() }
#Preview("Multi")  { MultiPhotoPreview() }
