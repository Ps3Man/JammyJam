import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search shows...", text: $viewModel.searchQuery)
                        .autocapitalization(.none)
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if viewModel.isLoading && viewModel.shows.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                    Spacer()
                } else if viewModel.shows.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No shows found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.shows) { show in
                            NavigationLink(destination: ShowDetailView(showId: show.id)) {
                                ShowListItem(show: show)
                            }
                        }
                        
                        if viewModel.hasMorePages {
                            HStack {
                                Spacer()
                                Button(action: {
                                    viewModel.loadMoreShows()
                                }) {
                                    Text(viewModel.isLoading ? "Loading..." : "Load More")
                                        .foregroundColor(Color("AccentColor"))
                                }
                                .disabled(viewModel.isLoading)
                                Spacer()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 10)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Explore")
            .onAppear {
                if viewModel.shows.isEmpty {
                    viewModel.loadShows()
                }
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(PlayerViewModel())
            .preferredColorScheme(.dark)
    }
} 