import Foundation
import Combine

class ShowDetailViewModel: ObservableObject {
    @Published var show: Show?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let archiveService = ArchiveService.shared
    
    func loadShow(identifier: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Use the existing getConcertDetails method
                let concert = try await archiveService.getConcertDetails(identifier: identifier)
                
                // Convert Concert to Show
                let show = Show(
                    id: concert.id,
                    title: concert.title,
                    date: concert.date,
                    venue: concert.venue,
                    location: concert.location,
                    description: nil,
                    tracks: concert.tracks,
                    imageUrl: concert.coverImageURL?.absoluteString
                )
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.show = show
                    self.isLoading = false
                }
            } catch {
                // Handle errors
                await MainActor.run {
                    self.errorMessage = "Failed to load show details: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
} 