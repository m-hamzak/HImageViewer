import SwiftUI
import HImageViewer

// MARK: - Root navigation

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section("SwiftUI") {
                    NavigationLink("Photo Gallery",     destination: PhotoGalleryExample())
                    NavigationLink("Mixed Media",       destination: MixedMediaExample())
                    NavigationLink("Remote Images",     destination: RemoteImagesExample())
                    NavigationLink("Glass Theme",       destination: GlassThemeExample())
                    NavigationLink("Classic Theme",     destination: ClassicThemeExample())
                    NavigationLink("Upload Progress",   destination: UploadProgressExample())
                    NavigationLink("With Delegate",     destination: DelegateExample())
                }
                Section("UIKit") {
                    NavigationLink("UIKit Launcher",    destination: UIKitLauncherExample())
                }
            }
            .navigationTitle("HImageViewer")
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Photo Gallery

struct PhotoGalleryExample: View {
    @State private var items: [MediaAsset] = MediaAsset.from(uiImages: [
        UIImage(systemName: "photo")!,
        UIImage(systemName: "photo.fill")!,
        UIImage(systemName: "photo.on.rectangle")!,
        UIImage(systemName: "photo.stack")!,
    ])
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("\(items.count) items in gallery")
                .foregroundStyle(.secondary)
            Button("Open Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Photo Gallery")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Mixed Media

struct MixedMediaExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(systemName: "photo")!)),
        .video(URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!),
        .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("2 photos + 1 video")
                .foregroundStyle(.secondary)
            Button("Open Mixed Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Mixed Media")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Remote Images

struct RemoteImagesExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=1")!)),
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=2")!)),
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=3")!)),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Fetched from picsum.photos")
                .foregroundStyle(.secondary)
            Button("Open Remote Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Remote Images")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Glass Theme (default)

struct GlassThemeExample: View {
    @State private var items = MediaAsset.from(uiImages: Array(repeating: UIImage(systemName: "photo")!, count: 3))
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Default theme — Liquid Glass controls")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Glass Theme")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)   // tintColor nil → Glass mode (default)
        }
    }
}

// MARK: - Classic Theme

struct ClassicThemeExample: View {
    @State private var items = MediaAsset.from(uiImages: Array(repeating: UIImage(systemName: "photo")!, count: 3))
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Classic theme with orange tint")
                .foregroundStyle(.secondary)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
        .navigationTitle("Classic Theme")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(tintColor: .orange)
            )
        }
    }
}

// MARK: - Upload Progress

struct UploadProgressExample: View {
    @State private var items = MediaAsset.from(uiImages: [UIImage(systemName: "photo")!])
    @State private var isPresented = false
    @StateObject private var uploadState = HImageViewerUploadState()

    var body: some View {
        VStack(spacing: 24) {
            Text("Simulates an upload with animated ring.\nViewer auto-dismisses at 100%.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open & Simulate Upload") {
                isPresented = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    simulateUpload()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Upload Progress")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(uploadState: uploadState)
            )
        }
    }

    private func simulateUpload() {
        var p = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            p = min(p + 0.04, 1.0)
            uploadState.progress = p
            if p >= 1.0 { timer.invalidate() }
        }
    }
}

// MARK: - Delegate Example

final class ExampleDelegate: HImageViewerControlDelegate {
    var lastAction: String = "—"

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        lastAction = "Save tapped. Comment: \"\(comment)\", photos: \(photos.count)"
    }

    func didTapCloseButton() {
        lastAction = "Close tapped"
    }

    func didDeleteMediaAssets(_ assets: [MediaAsset]) {
        lastAction = "Deleted \(assets.count) item(s)"
    }

    func didChangePage(to index: Int) {
        lastAction = "Page changed to \(index)"
    }
}

struct DelegateExample: View {
    @State private var items = MediaAsset.from(uiImages: [
        UIImage(systemName: "photo")!,
        UIImage(systemName: "star")!
    ])
    @State private var isPresented = false
    @State private var lastAction = "—"
    private let delegate = ExampleDelegate()

    var body: some View {
        VStack(spacing: 24) {
            Text("Last action:\n\(lastAction)")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("With Delegate")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(
                    showSaveButton: true,
                    showCommentBox: true,
                    delegate: delegate
                )
            )
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            lastAction = delegate.lastAction
        }
    }
}

// MARK: - UIKit Launcher

struct UIKitLauncherExample: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitExampleViewController {
        UIKitExampleViewController()
    }
    func updateUIViewController(_ vc: UIKitExampleViewController, context: Context) {}
}
