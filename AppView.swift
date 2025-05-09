import SwiftUI

struct AppView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                    .tag(1)
                
                PlaylistView()
                    .tabItem {
                        Label("Playlists", systemImage: "music.note.list")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .accentColor(Color("AccentColor"))
            .preferredColorScheme(.dark)
            
            // Mini player that appears when music is playing
            if playerViewModel.isShowingPlayer {
                MiniPlayerView()
                    .transition(.move(edge: .bottom))
            }
        }
        .environmentObject(playerViewModel)
    }
} 