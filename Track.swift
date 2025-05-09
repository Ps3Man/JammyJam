import Foundation

struct Track: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let duration: TimeInterval
    let audioURL: URL
    let trackNumber: Int
    let concertId: String
    var setNumber: Int? = nil
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Add alias for compatibility with views
    var durationFormatted: String {
        return formattedDuration
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
} 