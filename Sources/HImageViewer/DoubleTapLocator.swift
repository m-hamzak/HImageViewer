//
//  DoubleTapLocator.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

/// A transparent `UIViewRepresentable` overlay that intercepts double-taps and
/// reports their location in the view's local coordinate space.
///
/// Attach as an overlay on top of the image view:
/// ```swift
/// image.overlay(DoubleTapLocator { point in handleDoubleTap(at: point) })
/// ```
///
/// The underlying `UITapGestureRecognizer` uses `cancelsTouchesInView = false`
/// so all other gestures (pinch, pan, drag-to-dismiss) continue to work normally.
struct DoubleTapLocator: UIViewRepresentable {

    var onDoubleTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let recognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        recognizer.numberOfTapsRequired = 2
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDoubleTap = onDoubleTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var onDoubleTap: (CGPoint) -> Void

        init(onDoubleTap: @escaping (CGPoint) -> Void) {
            self.onDoubleTap = onDoubleTap
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            let point = recognizer.location(in: recognizer.view)
            onDoubleTap(point)
        }
    }
}
