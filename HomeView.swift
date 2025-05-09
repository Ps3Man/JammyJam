import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    VStack(alignment: .leading) {
                        Text("JammyJam")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Grateful Dead Live Shows")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Featured shows section
                    VStack(alignment: .leading) {
                        Text("Featured Shows")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.featuredShows) { show in
                                    NavigationLink(destination: ShowDetailView(showId: show.id)) {
                                        FeaturedShowCard(show: show)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 200)
                    }
                    
                    // Recent shows section
                    VStack(alignment: .leading) {
                        Text("Recent Additions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            ForEach(viewModel.recentShows) { show in
                                NavigationLink(destination: ShowDetailView(showId: show.id)) {
                                    ShowListItem(show: show)
                                }
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.refreshData()
            }
        }
    }
}

struct FeaturedShowCard: View {
    let show: ShowPreview
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Rectangle()
                    .fill(Color("AccentColor").opacity(0.2))
                    .cornerRadius(10)
                
                VStack {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color("AccentColor"))
                    
                    Text(show.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 120)
            
            Text(show.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(show.venue)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(.secondary)
            
            Text(show.location)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
    }
}

struct ShowListItem: View {
    let show: ShowPreview
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color("AccentColor").opacity(0.2))
                
                Image(systemName: "music.note")
                    .foregroundColor(Color("AccentColor"))
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(show.venue)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                
                Text("\(show.formattedDate) • \(show.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(PlayerViewModel())
            .preferredColorScheme(.dark)
    }
} 