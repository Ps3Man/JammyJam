import Foundation
import Combine

class ExploreViewModel: ObservableObject {
    @Published var shows: [ShowPreview] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let archiveService = ArchiveService.shared
    
    init() {
        // Setup search functionality with debounce
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.resetSearch()
                self?.loadShows()
            }
            .store(in: &cancellables)
    }
    
    func loadShows() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Use the existing searchConcerts method
                let concerts = try await archiveService.searchConcerts(
                    query: searchQuery.isEmpty ? nil : searchQuery,
                    page: currentPage
                )
                
                // Convert concerts to ShowPreview objects
                let newShows = concerts.map { concert in
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
                    if self.currentPage == 1 {
                        self.shows = newShows
                    } else {
                        self.shows.append(contentsOf: newShows)
                    }
                    
                    // Check if we should show the "load more" button
                    self.hasMorePages = !newShows.isEmpty
                    self.currentPage += 1
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
    
    func resetSearch() {
        shows = []
        currentPage = 1
        hasMorePages = true
    }
    
    func loadMoreShows() {
        loadShows()
    }
} 