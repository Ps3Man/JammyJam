import Foundation

struct Show: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let venue: String
    let location: String
    let description: String?
    let tracks: [Track]
    let imageUrl: String?
    
    // Computed property for displaying the date in a readable format
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Computed property for organizing tracks by set
    var tracksBySet: [Int: [Track]] {
        Dictionary(grouping: tracks, by: { $0.setNumber })
    }
    
    // Computed property for total duration of all tracks
    var totalDuration: Double {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    // Computed property for formatted total duration
    var totalDurationFormatted: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// Preview version of Show with minimal information
struct ShowPreview: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let venue: String
    let imageUrl: String?
    let location: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 