import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    
    private let userDefaultsKey = "savedPlaylists"
    
    init() {
        loadPlaylists()
    }
    
    func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedPlaylists = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decodedPlaylists
        }
    }
    
    func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func createPlaylist(name: String) {
        let newPlaylist = Playlist(id: UUID().uuidString, name: name, tracks: [])
        playlists.append(newPlaylist)
        savePlaylists()
    }
    
    func addTrackToPlaylist(track: Track, playlistId: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            // Check if track already exists in playlist
            if !playlists[index].tracks.contains(where: { $0.id == track.id }) {
                playlists[index].tracks.append(track)
                savePlaylists()
            }
        }
    }
    
    func removeTrackFromPlaylist(trackId: String, playlistId: String) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[playlistIndex].tracks.removeAll(where: { $0.id == trackId })
            savePlaylists()
        }
    }
    
    func deletePlaylist(playlistId: String) {
        playlists.removeAll(where: { $0.id == playlistId })
        savePlaylists()
    }
} 