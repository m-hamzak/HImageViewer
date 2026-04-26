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
/// ## Usage
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

    // MARK: - Caller binding (syncs mutations back)

    @Binding private var externalMediaAssets: [MediaAsset]

    // MARK: - ViewModel

    @StateObject private var vm: HImageViewerViewModel
    @Environment(\.dismiss) private var dismiss

    /// `true` when the hosting controller is pushed onto a UINavigationController
    /// rather than presented modally.
    @State private var isInNavigationStack: Bool = false

    /// Screen height sourced from the active UIWindowScene — avoids the deprecated UIScreen.main.
    private var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.height ?? 852
    }

    // MARK: - Initialisation

    /// Creates a new image/video viewer from a unified `MediaAsset` collection.
    ///
    /// - Parameters:
    ///   - mediaAssets: A binding to the array of `MediaAsset` objects to display.
    ///     Modified when items are deleted or reordered.
    ///   - initialIndex: The index of the item to display first. Clamped to a valid range.
    ///     Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to
    ///     standard configuration.
    public init(
        mediaAssets: Binding<[MediaAsset]>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._externalMediaAssets = mediaAssets
        self._vm = StateObject(wrappedValue: HImageViewerViewModel(
            mediaAssets: mediaAssets.wrappedValue,
            initialIndex: initialIndex,
            config: configuration
        ))
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Canvas — fills behind the status bar too.
            vm.config.backgroundColor.ignoresSafeArea()

            // Invisible detector — reads the UIKit responder chain on appear
            // to decide whether this hosting controller is pushed or presented.
            NavigationDetector { isPushed in
                isInNavigationStack = isPushed
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)

            mainComponent
                .offset(y: max(0, vm.dragOffset))
                .opacity(1 - vm.dragProgress * 0.35)
                .simultaneousGesture(isInNavigationStack ? nil : dragToDismissGesture)
                .onAppear {
                    if vm.uploadState.progress == 1.0 {
                        vm.uploadState.progress = nil
                    }
                }
                .disabled(vm.uploadState.progress ?? 0 > 0)

            if let progress = vm.uploadState.progress {
                VStack {
                    Spacer()
                    ProgressRingOverlayView(progress: progress, title: "Uploading")
                        .padding()
                        .opacity(progress < 1.0 ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: progress)
                        .onChangeCompat(of: progress) { newProgress in
                            guard newProgress >= 1 else { return }
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                dismiss()
                            }
                        }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onChangeCompat(of: vm.mediaAssets) { externalMediaAssets = $0 }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isInNavigationStack, let counter = vm.pageCounterText {
                    Text(counter)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .accessibilityLabel(vm.accessibilityPageCounterText ?? counter)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isInNavigationStack {
                    let buttonTint: Color = vm.config.isGlassMode
                        ? Color(.label)
                        : vm.config.resolvedTintColor
                    if vm.selectionMode {
                        Button("Cancel", action: vm.cancelSelection)
                            .font(.body.weight(.medium))
                            .foregroundStyle(buttonTint)
                            .accessibilityHint("Exits selection mode")
                    } else {
                        if vm.config.showEditButton && vm.currentPhotoAsset != nil {
                            Button {
                                guard let asset = vm.currentPhotoAsset else { return }
                                vm.delegate?.didTapEditButton(photo: asset)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(buttonTint)
                            .accessibilityLabel("Edit")
                            .accessibilityHint("Opens the photo editor")
                        }
                        if vm.totalCount > 1 {
                            Button { vm.selectionMode = true } label: {
                                Image(systemName: "checkmark")
                            }
                            .tint(buttonTint)
                            .accessibilityLabel("Select")
                            .accessibilityHint("Enters selection mode")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack(spacing: 0) {
            if !isInNavigationStack {
                TopBar(config: TopBarConfig(
                    showCloseButton: true,
                    showEditButton: vm.config.showEditButton && vm.currentPhotoAsset != nil,
                    showSelectButton: vm.totalCount > 1,
                    selectionMode: vm.selectionMode,
                    pageCounterText: vm.pageCounterText,
                    accessibilityPageLabel: vm.accessibilityPageCounterText,
                    tintColor: vm.config.resolvedTintColor,
                    isGlassMode: vm.config.isGlassMode,
                    onDismiss: { dismiss(); vm.delegate?.didTapCloseButton() },
                    onCancelSelection: { vm.cancelSelection() },
                    onSelectToggle: { vm.selectionMode = true },
                    onEdit: {
                        guard let asset = vm.currentPhotoAsset else { return }
                        vm.delegate?.didTapEditButton(photo: asset)
                    }
                ))
            }

            ZStack {
                if vm.selectionMode {
                    ScrollView {
                        MultiPhotoGrid(
                            mediaItems: vm.mediaAssets,
                            selectedIndices: vm.selectedIndices,
                            selectionMode: vm.selectionMode,
                            onSelectToggle: { vm.handleSelection($0) },
                            onReorder: { from, to in vm.reorderItems(from: from, to: to) }
                        )
                    }
                    .transition(.opacity)
                } else {
                    contentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: vm.selectionMode)

            if !vm.selectionMode {
                PageDotsView(currentIndex: vm.currentIndex, count: vm.totalCount)
            }

            BottomBar(comment: $vm.comment, config: BottomBarConfig(
                selectionMode: vm.selectionMode,
                showSaveButton: vm.shouldShowSaveButton,
                showCommentBox: vm.config.showCommentBox,
                title: vm.config.title,
                tintColor: vm.config.resolvedTintColor,
                isGlassMode: vm.config.isGlassMode,
                onSave: { vm.handleSave() },
                onDelete: { vm.handleDelete() }
            ))
        }
        .onChangeCompat(of: vm.totalCount) { newCount in
            if newCount == 0 {
                dismiss()
            } else {
                vm.currentIndex = min(vm.currentIndex, newCount - 1)
            }
        }
        .onChangeCompat(of: vm.selectionMode) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                vm.dragOffset = 0
            }
        }
    }

    // MARK: - Drag-to-Dismiss Gesture

    private var dragToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !vm.selectionMode, vm.uploadState.progress == nil else { return }
                let translation = value.translation
                guard translation.height > 0,
                      translation.height > abs(translation.width) * 1.5 else { return }
                vm.dragOffset = translation.height
            }
            .onEnded { value in
                let rawHeight = value.translation.height
                let predictedHeight = value.predictedEndTranslation.height
                let shouldDismiss = rawHeight > vm.dismissThreshold
                    || predictedHeight > vm.dismissThreshold

                if shouldDismiss {
                    vm.haptics.impact(.light)
                    withAnimation(.easeOut(duration: 0.25)) {
                        vm.dragOffset = screenHeight
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        dismiss()
                        vm.delegate?.didTapCloseButton()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        vm.dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if !vm.mediaAssets.isEmpty {
            TabView(selection: $vm.currentIndex) {
                ForEach(Array(vm.mediaAssets.enumerated()), id: \.1.id) { index, item in
                    Group {
                        switch item.kind {
                        case .photo(let asset):
                            PhotoView(
                                photo: asset,
                                isSinglePhotoMode: true,
                                tintColor: vm.config.resolvedTintColor,
                                placeholderView: vm.config.placeholderView,
                                errorView: vm.config.errorView,
                                resetToken: vm.currentIndex
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
    }
}

// MARK: - Navigation Detection

private struct NavigationDetector: UIViewRepresentable {

    var onDetect: (Bool) -> Void

    func makeUIView(context: Context) -> _DetectorView {
        _DetectorView(onDetect: onDetect)
    }

    func updateUIView(_ uiView: _DetectorView, context: Context) {
        uiView.onDetect = onDetect
    }

    final class _DetectorView: UIView {

        var onDetect: (Bool) -> Void

        init(onDetect: @escaping (Bool) -> Void) {
            self.onDetect = onDetect
            super.init(frame: .zero)
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { fatalError("not used") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let isPushed = self.parentViewController?.navigationController != nil
                self.onDetect(isPushed)
            }
        }

        private var parentViewController: UIViewController? {
            var responder: UIResponder? = next
            while let r = responder {
                if let vc = r as? UIViewController { return vc }
                responder = r.next
            }
            return nil
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
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(systemName: "person")!))
    ]
    var body: some View { HImageViewer(mediaAssets: $items) }
}

private struct MultiPhotoPreview: View {
    @State private var items: [MediaAsset] = (0..<5).map { _ in
        .photo(PhotoAsset(image: UIImage(systemName: "person")!))
    }
    var body: some View { HImageViewer(mediaAssets: $items) }
}

private struct MixedMediaPreview: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(systemName: "photo")!)),
        .photo(PhotoAsset(image: UIImage(systemName: "star")!))
    ]
    var body: some View { HImageViewer(mediaAssets: $items) }
}

#Preview("Single")      { SinglePhotoPreview() }
#Preview("Multi")       { MultiPhotoPreview() }
#Preview("Mixed Media") { MixedMediaPreview() }
