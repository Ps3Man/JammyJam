import SwiftUI

struct ShowDetailView: View {
    let showId: String
    @StateObject private var viewModel = ShowDetailViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var isAddToPlaylistSheetPresented = false
    @State private var selectedTrack: Track? = nil
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if let show = viewModel.show {
                VStack(alignment: .leading, spacing: 20) {
                    // Show header
                    VStack(alignment: .leading) {
                        Text(show.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(show.formattedDate)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(show.venue) • \(show.location)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let description = show.description {
                            Text(description)
                                .font(.body)
                                .padding(.top, 8)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(show.tracks.count) tracks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Total: \(show.totalDurationFormatted)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Play all tracks
                                if let firstTrack = show.tracks.first {
                                    playerViewModel.setPlaylist(tracks: show.tracks)
                                    playerViewModel.play(track: firstTrack, from: show)
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
                    .padding(.horizontal)
                    
                    // Tracks list
                    VStack(alignment: .leading) {
                        Text("Tracks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Group tracks by set
                        ForEach(Array(show.tracksBySet.keys).sorted(), id: \.self) { setNumber in
                            if let tracksInSet = show.tracksBySet[setNumber] {
                                VStack(alignment: .leading) {
                                    Text(setTitle(setNumber: setNumber))
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    
                                    ForEach(tracksInSet) { track in
                                        TrackListItem(
                                            track: track,
                                            isPlaying: playerViewModel.currentTrack?.id == track.id && playerViewModel.isPlaying,
                                            onPlay: {
                                                playerViewModel.setPlaylist(tracks: tracksInSet)
                                                playerViewModel.play(track: track, from: show)
                                            },
                                            onAddToPlaylist: {
                                                selectedTrack = track
                                                isAddToPlaylistSheetPresented = true
                                            }
                                        )
                                        
                                        Divider()
                                            .padding(.leading, 60)
                                            .padding(.trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // Add space for mini player
            }
        }
        .navigationBarTitle("Show Details", displayMode: .inline)
        .sheet(isPresented: $isAddToPlaylistSheetPresented) {
            if let track = selectedTrack {
                AddToPlaylistView(track: track)
            }
        }
        .onAppear {
            viewModel.loadShow(identifier: showId)
        }
    }
    
    private func setTitle(setNumber: Int) -> String {
        switch setNumber {
        case 1:
            return "Set 1"
        case 2:
            return "Set 2"
        case 3:
            return "Set 3"
        case 4:
            return "Encore"
        default:
            return "Set \(setNumber)"
        }
    }
}

struct TrackListItem: View {
    let track: Track
    let isPlaying: Bool
    let onPlay: () -> Void
    let onAddToPlaylist: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color("AccentColor") : Color("AccentColor").opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(isPlaying ? .white : Color("AccentColor"))
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
            
            Menu {
                Button(action: onAddToPlaylist) {
                    Label("Add to Playlist", systemImage: "plus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct AddToPlaylistView: View {
    let track: Track
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @State private var newPlaylistName = ""
    @State private var isShowingCreatePlaylist = false
    
    var body: some View {
        NavigationView {
            VStack {
                if playlistViewModel.playlists.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No playlists yet")
                            .font(.headline)
                        
                        Text("Create a new playlist to add this track")
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
                        ForEach(playlistViewModel.playlists) { playlist in
                            Button(action: {
                                playlistViewModel.addTrackToPlaylist(track: track, playlistId: playlist.id)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundColor(Color("AccentColor"))
                                    
                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                            .font(.headline)
                                        
                                        Text("\(playlist.tracks.count) tracks")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
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
                        playlistViewModel.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            } message: {
                Text("Enter a name for your new playlist")
            }
        }
    }
}

struct ShowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ShowDetailView(showId: "gd1977-05-08.sbd.cantor.29440")
            .environmentObject(PlayerViewModel())
            .preferredColorScheme(.dark)
    }
} 