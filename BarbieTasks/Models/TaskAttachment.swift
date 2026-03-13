import Foundation

struct TaskAttachment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var urlString: String   // file:// or https://
    var addedAt: Date = Date()

    var isLink: Bool { urlString.hasPrefix("http") }
    var url: URL? { URL(string: urlString) }
}
