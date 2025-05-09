import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    private let downloadsDirectory = "Downloads"
    private let favoritesKey = "favorites"
    private let recentlyPlayedKey = "recentlyPlayed"
    private let playlistsKey = "playlists"
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoryIfNeeded() {
        guard let documentsDirectory = getDocumentsDirectory() else { return }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        
        if !fileManager.fileExists(atPath: downloadsPath.path) {
            do {
                try fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
            } catch {
                print("Failed to create downloads directory: \(error)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - File Operations
    
    func downloadFile(from url: URL, trackId: String, progressHandler: @escaping (Float) -> Void) async throws -> Bool {
        guard let documentsDirectory = getDocumentsDirectory() else {
            throw PersistenceError.directoryNotFound
        }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        let destinationURL = downloadsPath.appendingPathComponent("\(trackId).mp3")
        
        // Check if file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            return true
        }
        
        // Create download task
        let (tempLocalURL, response) = try await URLSession.shared.download(from: url, delegate: DownloadProgressDelegate(progressHandler: progressHandler))
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PersistenceError.downloadFailed
        }
        
        // Move file to final location
        try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
        
        return true
    }
    
    func deleteFile(for trackId: String) {
        guard let documentsDirectory = getDocumentsDirectory() else { return }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        let fileURL = downloadsPath.appendingPathComponent("\(trackId).mp3")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
    }
    
    func fileExists(for trackId: String) -> Bool {
        guard let documentsDirectory = getDocumentsDirectory() else { return false }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        let fileURL = downloadsPath.appendingPathComponent("\(trackId).mp3")
        
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    func getLocalURL(for track: Track) -> URL? {
        guard let documentsDirectory = getDocumentsDirectory() else { return nil }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        let fileURL = downloadsPath.appendingPathComponent("\(track.id).mp3")
        
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    // MARK: - UserDefaults Operations
    
    func saveFavorites(_ favorites: [String]) {
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
    }
    
    func loadFavorites() -> [String] {
        return UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }
    
    func saveRecentlyPlayed(_ concerts: [Concert]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(concerts)
            UserDefaults.standard.set(data, forKey: recentlyPlayedKey)
        } catch {
            print("Failed to save recently played: \(error)")
        }
    }
    
    func loadRecentlyPlayed() -> [Concert] {
        guard let data = UserDefaults.standard.data(forKey: recentlyPlayedKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Concert].self, from: data)
        } catch {
            print("Failed to load recently played: \(error)")
            return []
        }
    }
    
    func savePlaylists(_ playlists: [Playlist]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }
    
    func loadPlaylists() -> [Playlist] {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Playlist].self, from: data)
        } catch {
            print("Failed to load playlists: \(error)")
            return []
        }
    }
    
    // MARK: - Storage Management
    
    func getDownloadedConcertIds() -> [String] {
        guard let documentsDirectory = getDocumentsDirectory() else { return [] }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        
        // Get list of all downloaded files
        let downloadedFiles = (try? fileManager.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: nil)) ?? []
        
        // Extract concert IDs from filenames
        return downloadedFiles.compactMap { url in
            let filename = url.deletingPathExtension().lastPathComponent
            // Format is concertId_filename, so extract the concertId
            let components = filename.components(separatedBy: "_")
            return components.first
        }
    }
    
    func getTotalDownloadSize() -> Int64 {
        guard let documentsDirectory = getDocumentsDirectory() else { return 0 }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        
        let downloadedFiles = (try? fileManager.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: [URLResourceKey.fileSizeKey])) ?? []
        
        return downloadedFiles.reduce(0) { totalSize, url in
            let fileSize = (try? url.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize) ?? 0
            return totalSize + Int64(fileSize)
        }
    }
    
    func clearAllDownloads() throws {
        guard let documentsDirectory = getDocumentsDirectory() else {
            throw PersistenceError.directoryNotFound
        }
        
        let downloadsPath = documentsDirectory.appendingPathComponent(downloadsDirectory)
        
        // Remove all files in the downloads directory
        let downloadedFiles = try fileManager.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: nil)
        
        for fileURL in downloadedFiles {
            try fileManager.removeItem(at: fileURL)
        }
    }
}

// Helper class for tracking download progress
class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    private let progressHandler: (Float) -> Void
    
    init(progressHandler: @escaping (Float) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        progressHandler(progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // This is handled in the downloadFile method
    }
}

enum PersistenceError: Error {
    case directoryNotFound
    case downloadFailed
    case fileNotFound
    case invalidURL
} 