//
//  View+OnChange.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 19/04/2026.
//

import SwiftUI

extension View {
    /// Backwards-compatible onChange that works from iOS 15 through iOS 17+.
    /// Uses the two-argument closure on iOS 17+ (non-deprecated) and the
    /// single-argument form on iOS 15/16.
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, newValue in action(newValue) }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}
