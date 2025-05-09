import SwiftUI

struct PlaylistView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var newPlaylistName = ""
    @State private var isShowingCreatePlaylist = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.playlists.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No playlists yet")
                            .font(.headline)
                        
                        Text("Create a playlist to save your favorite tracks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            isShowingCreatePlaylist = true
                        }) {
                            Text("Create Playlist")
                                .font(.headline)
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                HStack {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color("AccentColor").opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(8)
                                        
                                        Image(systemName: "music.note.list")
                                            .foregroundColor(Color("AccentColor"))
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                            .font(.headline)
                                        
                                        Text("\(playlist.tracks.count) tracks • \(playlist.totalDurationFormatted)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    viewModel.deletePlaylist(playlistId: playlist.id)
                                }) {
                                    Label("Delete Playlist", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Playlists")
            .navigationBarItems(
                trailing: Button(action: {
                    isShowingCreatePlaylist = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .alert("Create Playlist", isPresented: $isShowingCreatePlaylist) {
                TextField("Playlist Name", text: $newPlaylistName)
                
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    if !newPlaylistName.isEmpty {
                        viewModel.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            } message: {
                Text("Enter a name for your new playlist")
            }
        }
    }
}

struct PlaylistDetailView: View {
    @State var playlist: Playlist
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if playlist.tracks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No tracks in this playlist")
                        .font(.headline)
                    
                    Text("Add tracks from show details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                // Playlist header
                VStack(alignment: .leading) {
                    Text(playlist.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(playlist.tracks.count) tracks • \(playlist.totalDurationFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            // Play all tracks in playlist
                            if let firstTrack = playlist.tracks.first {
                                playerViewModel.setPlaylist(tracks: playlist.tracks)
                                // We don't have a Show for playlists, so create a temporary one
                                let tempShow = Show(
                                    id: "playlist-\(playlist.id)",
                                    title: playlist.name,
                                    date: Date(),
                                    venue: "Playlist",
                                    location: "",
                                    description: nil,
                                    tracks: playlist.tracks,
                                    imageUrl: nil
                                )
                                playerViewModel.play(track: firstTrack, from: tempShow)
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play All")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
                
                // Track list
                List {
                    ForEach(playlist.tracks) { track in
                        HStack {
                            Button(action: {
                                // Play the track
                                playerViewModel.setPlaylist(tracks: playlist.tracks)
                                // We don't have a Show for playlists, so create a temporary one
                                let tempShow = Show(
                                    id: "playlist-\(playlist.id)",
                                    title: playlist.name,
                                    date: Date(),
                                    venue: "Playlist",
                                    location: "",
                                    description: nil,
                                    tracks: playlist.tracks,
                                    imageUrl: nil
                                )
                                playerViewModel.play(track: track, from: tempShow)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(playerViewModel.currentTrack?.id == track.id && playerViewModel.isPlaying ? Color("AccentColor") : Color("AccentColor").opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: playerViewModel.currentTrack?.id == track.id && playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                        .foregroundColor(playerViewModel.currentTrack?.id == track.id && playerViewModel.isPlaying ? .white : Color("AccentColor"))
                                        .font(.system(size: 16))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.body)
                                    .lineLimit(1)
                                
                                Text(track.durationFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            Button(action: {
                                // Remove track from playlist
                                playlistViewModel.removeTrackFromPlaylist(trackId: track.id, playlistId: playlist.id)
                                
                                // Update local state
                                if let updatedPlaylist = playlistViewModel.playlists.first(where: { $0.id == playlist.id }) {
                                    playlist = updatedPlaylist
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle("Playlist", displayMode: .inline)
        .onAppear {
            // Refresh playlist data when the view appears
            if let updatedPlaylist = playlistViewModel.playlists.first(where: { $0.id == playlist.id }) {
                playlist = updatedPlaylist
            }
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
            .environmentObject(PlayerViewModel())
            .preferredColorScheme(.dark)
    }
} 