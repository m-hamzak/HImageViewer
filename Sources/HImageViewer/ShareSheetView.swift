//
//  ShareSheetView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 26/04/2026.
//

import SwiftUI

/// A thin `UIViewControllerRepresentable` that presents `UIActivityViewController`.
///
/// Present this view via a `.sheet(isPresented:)` modifier. It dismisses itself
/// automatically after the share interaction completes.
struct ShareSheetView: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
