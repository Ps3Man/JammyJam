import Foundation

class ArchiveService {
    static let shared = ArchiveService()
    
    private let baseURL = "https://archive.org"
    private let searchEndpoint = "/advancedsearch.php"
    private let metadataEndpoint = "/metadata"
    private let downloadEndpoint = "/download"
    
    private init() {}
    
    // MARK: - Main API Methods
    
    /// Search for Grateful Dead concerts with optional filters
    func searchConcerts(query: String? = nil, year: Int? = nil, venue: String? = nil, page: Int = 1) async throws -> [Concert] {
        // Build the search URL with appropriate parameters
        var urlComponents = URLComponents(string: baseURL + searchEndpoint)
        
        // Default query: look for items in the GratefulDead collection
        var searchQuery = "collection:(GratefulDead)"
        
        // Add text search if provided
        if let query = query, !query.isEmpty {
            searchQuery += " AND (\(query))"
        }
        
        // Add year filter if provided
        if let year = year {
            searchQuery += " AND year:\(year)"
        }
        
        // Add venue filter if provided
        if let venue = venue, !venue.isEmpty {
            searchQuery += " AND venue:\(venue)"
        }
        
        // Build query parameters
        let queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "fl[]", value: "identifier,title,date,venue,coverage,year"),
            URLQueryItem(name: "sort[]", value: "date desc"),
            URLQueryItem(name: "rows", value: "50"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "output", value: "json")
        ]
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        // Parse the response
        let searchResponse = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
        
        // Map response to our Concert model
        return searchResponse.response.docs.compactMap { doc in
            guard let identifier = doc.identifier,
                  let title = doc.title,
                  let dateString = doc.date,
                  let venue = doc.venue,
                  let coverage = doc.coverage,
                  let year = doc.year else {
                return nil
            }
            
            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: dateString) else {
                return nil
            }
            
            // Create placeholder concert (tracks will be loaded on demand)
            return Concert(
                id: identifier,
                title: title,
                date: date,
                venue: venue,
                location: coverage,
                year: year,
                coverImageURL: URL(string: "\(baseURL)/services/img/\(identifier)"),
                tracks: [],
                source: "Archive.org"
            )
        }
    }
    
    /// Get detailed information about a specific concert
    func getConcertDetails(identifier: String) async throws -> Concert {
        let url = URL(string: baseURL + metadataEndpoint + "/" + identifier)!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        // Parse metadata response
        let metadataResponse = try JSONDecoder().decode(ArchiveMetadataResponse.self, from: data)
        
        // Get files data to build tracks
        let tracks = try await getTracksForConcert(identifier: identifier)
        
        // Extract metadata
        guard let metadata = metadataResponse.metadata,
              let title = metadata.title.first,
              let dateString = metadata.date.first else {
            throw NetworkError.invalidData
        }
        
        // Extract optional values with fallbacks
        let venue = metadata.venue?.first ?? metadata.coverage?.first ?? "Unknown"
        let coverage = metadata.coverage?.first ?? "Unknown"
        let yearString = metadata.year.first ?? "0"
        let year = Int(yearString) ?? 0
        
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: dateString) ?? Date()
        
        // Build source info
        let source = metadata.source?.first ?? "Unknown Source"
        
        // Create full concert with tracks
        return Concert(
            id: identifier,
            title: title,
            date: date,
            venue: venue,
            location: coverage,
            year: year,
            coverImageURL: URL(string: "\(baseURL)/services/img/\(identifier)"),
            tracks: tracks,
            source: source
        )
    }
    
    /// Get audio tracks for a specific concert
    private func getTracksForConcert(identifier: String) async throws -> [Track] {
        let url = URL(string: baseURL + downloadEndpoint + "/" + identifier + "?format=json")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        // Parse files response
        let filesResponse = try JSONDecoder().decode(ArchiveFilesResponse.self, from: data)
        
        // Filter audio files (mp3 or flac) and sort by name
        let audioFiles = filesResponse.files
            .filter { $0.format == "VBR MP3" || $0.format == "Flac" }
            .filter { $0.title != nil }
            .sorted { ($0.track ?? 0) < ($1.track ?? 0) }
        
        // Convert to Track objects
        return audioFiles.enumerated().compactMap { index, file in
            guard let title = file.title,
                  let fileName = file.name else {
                return nil
            }
            
            let audioURL = URL(string: "\(baseURL)\(downloadEndpoint)/\(identifier)/\(fileName)")!
            let duration = file.length?.timeInterval ?? 0
            
            return Track(
                id: "\(identifier)_\(fileName)",
                title: title,
                duration: duration,
                audioURL: audioURL,
                trackNumber: file.track ?? index + 1,
                concertId: identifier
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get recommended concerts (e.g., shows from a specific year or venue)
    func getRecommendedConcerts() async throws -> [Concert] {
        // Get classic years (1972-1974 are considered prime Dead years)
        let classicYears = [1972, 1973, 1974, 1977]
        let randomYear = classicYears.randomElement() ?? 1972
        
        return try await searchConcerts(year: randomYear)
    }
    
    /// Get concerts that happened on this day in history
    func getOnThisDayConcerts() async throws -> [Concert] {
        let today = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        // Search for concerts on this month and day
        let dateQuery = String(format: "%02d-%02d", month, day)
        return try await searchConcerts(query: dateQuery)
    }
}

// Response Models for Archive.org API
struct ArchiveSearchResponse: Codable {
    let response: SearchResponseDocs
}

struct SearchResponseDocs: Codable {
    let docs: [ArchiveDoc]
}

struct ArchiveDoc: Codable {
    let identifier: String?
    let title: String?
    let date: String?
    let venue: String?
    let coverage: String?
    let year: Int?
}

struct ArchiveMetadataResponse: Codable {
    let metadata: ArchiveMetadata?
}

struct ArchiveMetadata: Codable {
    let identifier: [String]
    let title: [String]
    let date: [String]
    let venue: [String]?
    let coverage: [String]?
    let year: [String]
    let source: [String]?
}

struct ArchiveFilesResponse: Codable {
    let files: [ArchiveFile]
}

struct ArchiveFile: Codable {
    let name: String?
    let title: String?
    let format: String?
    let track: Int?
    let length: String?
    
    var timeInterval: TimeInterval? {
        guard let length = length else { return nil }
        
        let components = length.split(separator: ":")
        if components.count == 2 {
            // MM:SS format
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else {
                return nil
            }
            return minutes * 60 + seconds
        } else if components.count == 3 {
            // HH:MM:SS format
            guard let hours = Double(components[0]),
                  let minutes = Double(components[1]),
                  let seconds = Double(components[2]) else {
                return nil
            }
            return hours * 3600 + minutes * 60 + seconds
        }
        
        return nil
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
} 