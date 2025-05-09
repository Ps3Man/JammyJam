import Foundation

struct Playlist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var tracks: [Track]
    var coverImageURL: URL?
    var dateCreated: Date = Date()
    
    var trackCount: Int {
        return tracks.count
    }
    
    var totalDuration: TimeInterval {
        return tracks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Add alias for compatibility with views
    var totalDurationFormatted: String {
        return formattedDuration
    }
} 