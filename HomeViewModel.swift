import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var recentShows: [ShowPreview] = []
    @Published var featuredShows: [ShowPreview] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let archiveService = ArchiveService.shared
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Create a task to handle the async call
        Task {
            do {
                // Use the existing searchConcerts method
                let concerts = try await archiveService.searchConcerts(page: 1)
                
                // Convert concerts to ShowPreview objects
                let shows = concerts.map { concert in
                    return ShowPreview(
                        id: concert.id,
                        title: concert.title,
                        date: concert.date,
                        venue: concert.venue,
                        imageUrl: concert.coverImageURL?.absoluteString,
                        location: concert.location
                    )
                }
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.recentShows = shows
                    
                    // Select a few shows as featured
                    if shows.count > 3 {
                        let selectedIndices = Array(0..<min(3, shows.count))
                        self.featuredShows = selectedIndices.map { shows[$0] }
                    } else {
                        self.featuredShows = shows
                    }
                    
                    self.isLoading = false
                }
            } catch {
                // Handle errors
                await MainActor.run {
                    self.errorMessage = "Failed to load shows: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
} 