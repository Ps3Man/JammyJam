import SwiftUI

struct ConcertCard: View {
    let concert: Concert
    let action: () -> Void
    
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover image
                ZStack(alignment: .bottomTrailing) {
                    if let imageURL = concert.coverImageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(UIColor.systemGray5))
                                    .aspectRatio(1, contentMode: .fill)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                ZStack {
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    Image(systemName: "music.note")
                                        .font(.largeTitle)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            @unknown default:
                                Rectangle()
                                    .fill(Color(UIColor.systemGray5))
                            }
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Fallback gradient for concerts without images
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Download indicator
                    if playerViewModel.isConcertDownloaded(concert) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .padding(-2)
                            )
                            .padding(8)
                    }
                }
                
                // Concert info
                VStack(alignment: .leading, spacing: 2) {
                    Text(concert.venue)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(concert.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 