import Foundation
import SwiftUI

struct BarbieProject: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var colorHex: String
    var sortOrder: Int = 0

    var color: Color {
        Color(hex: colorHex)
    }
}
