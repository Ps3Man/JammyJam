import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var isShowingFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at the top
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color("AccentColor"))
                        .frame(width: calculateProgress(geometry: geometry), height: 2)
                }
            }
            .frame(height: 2)
            
            // Main mini player content
            Button(action: {
                isShowingFullPlayer = true
            }) {
                HStack {
                    // Album/show art or placeholder
                    ZStack {
                        Rectangle()
                            .fill(Color("AccentColor").opacity(0.2))
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        
                        Image(systemName: "music.note")
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    // Track info
                    VStack(alignment: .leading) {
                        if let track = playerViewModel.currentTrack {
                            Text(track.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let show = playerViewModel.currentShow {
                                Text(show.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        } else {
                            Text("Not Playing")
                                .font(.headline)
                        }
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Playback controls
                    HStack(spacing: 20) {
                        Button(action: {
                            playerViewModel.skipBackward()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                        .disabled(playerViewModel.currentTrack == nil)
                        
                        Button(action: {
                            playerViewModel.togglePlayPause()
                        }) {
                            Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                        .disabled(playerViewModel.currentTrack == nil)
                        
                        Button(action: {
                            playerViewModel.skipForward()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                        .disabled(playerViewModel.currentTrack == nil)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $isShowingFullPlayer) {
            FullPlayerView()
                .environmentObject(playerViewModel)
        }
    }
    
    private func calculateProgress(geometry: GeometryProxy) -> CGFloat {
        if playerViewModel.duration > 0 {
            let progress = playerViewModel.currentTime / playerViewModel.duration
            return geometry.size.width * CGFloat(progress)
        }
        return 0
    }
}

struct FullPlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Navigation/Close button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding()
                }
                
                Spacer()
                
                Text("Now Playing")
                    .font(.headline)
                
                Spacer()
                
                // Balance button for symmetry
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.clear)
                    .padding()
            }
            
            Spacer()
            
            // Album/Show artwork
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("AccentColor").opacity(0.2))
                    .frame(width: 300, height: 300)
                
                VStack {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color("AccentColor"))
                    
                    if let show = playerViewModel.currentShow {
                        Text(show.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 30)
            
            // Track info
            VStack(spacing: 8) {
                if let track = playerViewModel.currentTrack {
                    Text(track.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                }
                
                if let show = playerViewModel.currentShow {
                    Text(show.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("\(show.venue) • \(show.location)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Playback progress
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { playerViewModel.currentTime },
                    set: { playerViewModel.seekTo(time: $0) }
                ), in: 0...max(playerViewModel.duration, 1))
                .accentColor(Color("AccentColor"))
                
                HStack {
                    Text(formatTime(playerViewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(playerViewModel.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Playback controls
            HStack(spacing: 50) {
                Button(action: {
                    playerViewModel.skipBackward()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    playerViewModel.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("AccentColor"))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: {
                    playerViewModel.skipForward()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            Spacer()
        }
        .preferredColorScheme(.dark)
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MiniPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MiniPlayerView()
            .environmentObject(PlayerViewModel())
            .preferredColorScheme(.dark)
    }
} 