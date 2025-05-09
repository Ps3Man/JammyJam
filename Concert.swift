import Foundation

struct Concert: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let date: Date
    let venue: String
    let location: String
    let year: Int
    let coverImageURL: URL?
    var tracks: [Track]
    let source: String
    var isFavorite: Bool = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    static func == (lhs: Concert, rhs: Concert) -> Bool {
        return lhs.id == rhs.id
    }
} 