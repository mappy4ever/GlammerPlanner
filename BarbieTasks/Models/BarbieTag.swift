import Foundation
import SwiftUI

struct BarbieTag: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String

    var color: Color { Color(hex: colorHex) }
}
