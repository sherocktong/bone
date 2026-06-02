import Foundation
import SwiftUI

struct Buffer: Codable, Identifiable, Equatable {
    let id: Int
    var title: String
    var content: String
    var lastModified: Date

    static let colors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .indigo,
        .purple
    ]

    static let defaultTitles = [
        "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Purple"
    ]

    var color: Color {
        guard id >= 0 && id < Buffer.colors.count else { return .gray }
        return Buffer.colors[id]
    }

    static func `default`(id: Int) -> Buffer {
        Buffer(
            id: id,
            title: defaultTitles[id],
            content: "",
            lastModified: Date()
        )
    }
}
