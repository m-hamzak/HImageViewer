//
//  Array+Safe.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 26/04/2026.
//

extension Array {
    /// Returns the element at `index` if it is within bounds, otherwise `nil`.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
