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
/// `HImageViewer` provides a full-screen paged viewer with support for:
/// - Swipe paging through all items
/// - Pinch-to-zoom and double-tap zoom on photos
/// - Native AVKit controls for videos
/// - Multi-item selection and deletion via grid overlay
/// - Optional comment/title display
/// - Upload progress tracking
/// - Drag-to-dismiss
///
/// ## Photo-only usage (legacy)
///
/// ```swift
/// @State var assets = PhotoAsset.from(uiImages: myImages)
/// @State var selectedVideo: URL? = nil
///
/// HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
/// ```
///
/// ## Mixed photo + video usage
///
/// ```swift
/// @State var items: [MediaAsset] = [
///     .photo(PhotoAsset(image: myImage)),
///     .video(videoURL)
/// ]
///
/// HImageViewer(mediaAssets: $items)
/// ```
///
/// - Important: The viewer automatically dismisses when all items are deleted.
public struct HImageViewer: View {

    // MARK: - Legacy state (photo-only init)

    @Binding private var assets: [PhotoAsset]
    @Binding private var selectedVideo: URL?

    // MARK: - Media mode state

    @Binding private var mediaAssets: [MediaAsset]
    private let usesMediaMode: Bool

    // MARK: - Shared state

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

    /// Total number of items — photos+videos in media mode, photos in legacy mode.
    private var totalCount: Int {
        usesMediaMode ? mediaAssets.count : assets.count
    }

    /// The `PhotoAsset` at the current index, or `nil` if the current item is a video.
    private var currentPhotoAsset: PhotoAsset? {
        if usesMediaMode {
            return mediaAssets[safe: currentIndex]?.photoAsset
        }
        return assets[safe: currentIndex]
    }

    /// `"2 / 5"` when there are multiple items and not in selection mode; `nil` otherwise.
    private var pageCounterText: String? {
        guard totalCount > 1, !selectionMode else { return nil }
        return "\(currentIndex + 1) / \(totalCount)"
    }

    /// Natural-language equivalent of `pageCounterText` for VoiceOver, e.g. `"Page 2 of 5"`.
    private var accessibilityPageCounterText: String? {
        guard totalCount > 1, !selectionMode else { return nil }
        return "Page \(currentIndex + 1) of \(totalCount)"
    }

    /// 0→1 progress of the drag towards the dismiss threshold.
    private var dragProgress: Double {
        min(Double(max(0, dragOffset)) / Double(dismissThreshold), 1.0)
    }

    // MARK: - Initialisation (mixed photo + video)

    /// Creates a new image/video viewer from a unified `MediaAsset` collection.
    ///
    /// Use this initialiser to display a mix of photos and videos in the same gallery.
    ///
    /// - Parameters:
    ///   - mediaAssets: A binding to the array of `MediaAsset` objects to display.
    ///     Modified when items are deleted.
    ///   - initialIndex: The index of the item to display first. Clamped to a valid range.
    ///     Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to standard
    ///     configuration.
    public init(
        mediaAssets: Binding<[MediaAsset]>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._mediaAssets = mediaAssets
        self._assets = .constant([])
        self._selectedVideo = .constant(nil)
        self.usesMediaMode = true
        self.config = configuration
        self._comment = State(initialValue: configuration.initialComment ?? "")
        self.delegate = configuration.delegate

        let count = mediaAssets.wrappedValue.count
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        self._currentIndex = State(initialValue: clamped)

        if let provided = configuration.uploadState {
            uploadState = provided
        } else {
            uploadState = HImageViewerUploadState()
        }
    }

    // MARK: - Initialisation (photo-only, legacy)

    /// Creates a new image viewer instance.
    ///
    /// - Parameters:
    ///   - assets: A binding to the array of `PhotoAsset` objects to display. Modified when photos
    ///     are deleted.
    ///   - selectedVideo: A binding to an optional video URL. If non-nil, displays a video player
    ///     instead of the photo gallery.
    ///   - initialIndex: The index of the photo to display first. Clamped to a valid range.
    ///     Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to standard
    ///     configuration.
    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._assets = assets
        self._selectedVideo = selectedVideo
        self._mediaAssets = .constant([])
        self.usesMediaMode = false
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
            // Pure black canvas — fills behind the status bar too.
            Color.black.ignoresSafeArea()

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
        // In glass mode, force dark appearance so materials render as dark frosted glass
        // and white icons/text are always legible against the black canvas.
        // In classic (tinted) mode, follow the system color scheme.
        .preferredColorScheme(config.isGlassMode ? .dark : nil)
    }

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack(spacing: 0) {
            TopBar(config: TopBarConfig(
                showEditButton: config.showEditButton && currentPhotoAsset != nil,
                showSelectButton: totalCount > 1,
                selectionMode: selectionMode,
                pageCounterText: pageCounterText,
                accessibilityPageLabel: accessibilityPageCounterText,
                tintColor: config.resolvedTintColor,
                isGlassMode: config.isGlassMode,
                onDismiss: { dismiss(); delegate?.didTapCloseButton() },
                onCancelSelection: {
                    selectionMode = false
                    selectedIndices.removeAll()
                },
                onSelectToggle: { selectionMode = true },
                onEdit: {
                    guard let currentPhotoAsset else { return }
                    delegate?.didTapEditButton(photo: currentPhotoAsset)
                }
            ))

            ZStack {
                contentView
                if selectionMode {
                    let gridItems: [MediaAsset] = usesMediaMode
                        ? mediaAssets
                        : assets.map { MediaAsset.photo($0) }
                    MultiPhotoGrid(
                        mediaItems: gridItems,
                        selectedIndices: selectedIndices,
                        selectionMode: selectionMode,
                        onSelectToggle: handleSelection
                    )
                    .background(.regularMaterial)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectionMode)

            if !selectionMode {
                PageDotsView(currentIndex: currentIndex, count: totalCount)
            }

            BottomBar(comment: $comment, config: BottomBarConfig(
                selectionMode: selectionMode,
                showSaveButton: shouldShowSaveButton,
                showCommentBox: config.showCommentBox,
                title: config.title,
                tintColor: config.resolvedTintColor,
                isGlassMode: config.isGlassMode,
                onSave: { handleSave() },
                onDelete: { handleDelete() }
            ))
        }
        .onChangeCompat(of: currentPhotoAsset?.image) { newImage in
            guard newImage != nil else { return }
            wasImageEdited = true
        }
        .onChangeCompat(of: totalCount) { newCount in
            if newCount == 0 {
                dismiss()
            } else {
                currentIndex = min(currentIndex, newCount - 1)
            }
        }
        .onChangeCompat(of: selectionMode) { _ in
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
                // conflicting with horizontal TabView paging.
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

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if usesMediaMode {
            if !mediaAssets.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(mediaAssets.enumerated()), id: \.1.id) { index, item in
                        Group {
                            switch item.kind {
                            case .photo(let asset):
                                PhotoView(
                                    photo: asset,
                                    isSinglePhotoMode: true,
                                    tintColor: config.resolvedTintColor,
                                    placeholderView: config.placeholderView,
                                    errorView: config.errorView
                                )
                                .padding(.horizontal)
                            case .video(let url):
                                VideoPlayerView(videoURL: url)
                                    .padding()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        } else if let videoURL = selectedVideo {
            VideoPlayerView(videoURL: videoURL)
                .padding()
        } else if !assets.isEmpty {
            TabView(selection: $currentIndex) {
                ForEach(Array(assets.enumerated()), id: \.1.id) { index, asset in
                    PhotoView(
                        photo: asset,
                        isSinglePhotoMode: true,
                        tintColor: config.resolvedTintColor,
                        placeholderView: config.placeholderView,
                        errorView: config.errorView
                    )
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
        if usesMediaMode {
            let deletedIDs = Set(selectedIndices.compactMap { mediaAssets[safe: $0]?.id })
            mediaAssets.removeAll { deletedIDs.contains($0.id) }
            selectedIndices.removeAll()
            selectionMode = false
            if !mediaAssets.isEmpty {
                currentIndex = min(currentIndex, mediaAssets.count - 1)
            }
        } else {
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
    }

    // MARK: - Save Handling

    private func handleSave() {
        if usesMediaMode {
            let photos = mediaAssets.compactMap(\.photoAsset)
            delegate?.didTapSaveButton(comment: comment, photos: photos)
        } else {
            delegate?.didTapSaveButton(comment: comment, photos: assets)
        }
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

private struct MixedMediaPreview: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(systemName: "photo")!)),
        .photo(PhotoAsset(image: UIImage(systemName: "star")!))
    ]
    var body: some View {
        HImageViewer(mediaAssets: $items)
    }
}

#Preview("Single")      { SinglePhotoPreview() }
#Preview("Multi")       { MultiPhotoPreview() }
#Preview("Mixed Media") { MixedMediaPreview() }
