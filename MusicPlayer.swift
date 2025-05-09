import Foundation
import AVFoundation
import Combine
import MediaPlayer

class PlayerViewModel: ObservableObject, Sendable {
    static let shared = PlayerViewModel()
    
    // Player state
    @Published var currentTrack: Track?
    @Published var currentConcert: Concert?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isShowingPlayer: Bool = false
    @Published var isFullScreenPlayer: Bool = false
    @Published var isDownloaded: Bool = false
    
    // Playback history
    @Published var recentlyPlayed: [Concert] = []
    
    // Download state
    @Published var downloadProgress: Float = 0
    @Published var isDownloading: Bool = false
    
    // AVPlayer
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    // Queue management
    private var queue: [Track] = []
    private var queueIndex: Int = 0
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {
        setupRemoteCommandCenter()
        loadRecentlyPlayed()
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    
    func play(track: Track, from concert: Concert) {
        // If we're already playing this track, just toggle play/pause
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }
        
        // Check if track is downloaded
        if let localURL = persistenceManager.getLocalURL(for: track) {
            playFromLocalURL(track: track, concert: concert, url: localURL)
        } else {
            playFromRemoteURL(track: track, concert: concert)
        }
        
        // Show player and update UI
        updateNowPlayingInfo()
        addToRecentlyPlayed(concert)
        isShowingPlayer = true
    }
    
    private func playFromLocalURL(track: Track, concert: Concert, url: URL) {
        print("Playing from local file: \(url)")
        isDownloaded = true
        
        currentTrack = track
        currentConcert = concert
        
        preparePlayer(with: url)
    }
    
    private func playFromRemoteURL(track: Track, concert: Concert) {
        print("Playing from remote URL: \(track.audioURL)")
        isDownloaded = false
        
        currentTrack = track
        currentConcert = concert
        
        preparePlayer(with: track.audioURL)
    }
    
    private func preparePlayer(with url: URL) {
        // Remove old observer
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        
        // Create new player
        let playerItem = AVPlayerItem(url: url)
        self.playerItem = playerItem
        
        player = AVPlayer(playerItem: playerItem)
        
        // Set up time observation
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Get duration when available
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Start playing
        player?.play()
        isPlaying = true
        
        // Get duration
        if let duration = playerItem.asset.load(.duration).seconds, !duration.isNaN {
            self.duration = duration
        } else {
            // Sometimes duration isn't immediately available
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                if let duration = playerItem.asset.load(.duration).seconds, !duration.isNaN {
                    self?.duration = duration
                }
            }
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
        updateNowPlayingInfo()
    }
    
    func skipForward(seconds: TimeInterval = 15) {
        guard let player = player else { return }
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    @objc private func playerItemDidPlayToEndTime() {
        playNextTrack()
    }
    
    // MARK: - Queue Management
    
    func setQueue(tracks: [Track], startingAt index: Int = 0) {
        queue = tracks
        queueIndex = index
    }
    
    func playNextTrack() {
        guard let currentConcert = currentConcert, 
              let currentTrack = currentTrack,
              let currentIndex = currentConcert.tracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            return
        }
        
        // Check if there's a next track in the concert
        if currentIndex + 1 < currentConcert.tracks.count {
            let nextTrack = currentConcert.tracks[currentIndex + 1]
            play(track: nextTrack, from: currentConcert)
        } else {
            // End of concert
            isPlaying = false
            currentTime = 0
        }
    }
    
    func playPreviousTrack() {
        guard let currentConcert = currentConcert, 
              let currentTrack = currentTrack,
              let currentIndex = currentConcert.tracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            return
        }
        
        // If we're more than 3 seconds into the track, restart it
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        // Check if there's a previous track in the concert
        if currentIndex > 0 {
            let previousTrack = currentConcert.tracks[currentIndex - 1]
            play(track: previousTrack, from: currentConcert)
        } else {
            // Beginning of concert, just restart the current track
            seek(to: 0)
        }
    }
    
    // MARK: - Recently Played Management
    
    private func addToRecentlyPlayed(_ concert: Concert) {
        // Remove if already in list
        recentlyPlayed.removeAll { $0.id == concert.id }
        
        // Add to front of list
        recentlyPlayed.insert(concert, at: 0)
        
        // Keep only 10 most recent
        if recentlyPlayed.count > 10 {
            recentlyPlayed = Array(recentlyPlayed.prefix(10))
        }
        
        // Persist to storage
        saveRecentlyPlayed()
    }
    
    private func saveRecentlyPlayed() {
        persistenceManager.saveRecentlyPlayed(recentlyPlayed)
    }
    
    private func loadRecentlyPlayed() {
        recentlyPlayed = persistenceManager.loadRecentlyPlayed()
    }
    
    // MARK: - Media Controls
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            if !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            
            if self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPreviousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let currentTrack = currentTrack, 
              let currentConcert = currentConcert else {
            return
        }
        
        // Create now playing info
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Grateful Dead"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "\(currentConcert.venue) (\(currentConcert.formattedDate))"
        
        // Add duration and current time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        // Set playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Add artwork if available
        if let coverURL = currentConcert.coverImageURL {
            // In a real app, you'd download the image asynchronously
            // For now, we'll use a placeholder
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
                return UIImage(named: "GratefulDeadLogo") ?? UIImage(systemName: "music.note")!
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Set the now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Download Management
    
    func downloadTrack(_ track: Track) async -> Bool {
        isDownloading = true
        downloadProgress = 0
        
        do {
            let success = try await persistenceManager.downloadFile(from: track.audioURL, 
                                                              trackId: track.id,
                                                              progressHandler: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.downloadProgress = progress
                }
            })
            
            DispatchQueue.main.async {
                self.isDownloading = false
                if success {
                    self.isDownloaded = true
                }
            }
            
            return success
        } catch {
            print("Download failed: \(error)")
            DispatchQueue.main.async {
                self.isDownloading = false
            }
            return false
        }
    }
    
    func downloadConcert(_ concert: Concert) async -> Bool {
        var allSucceeded = true
        
        for track in concert.tracks {
            let success = await downloadTrack(track)
            if !success {
                allSucceeded = false
            }
        }
        
        return allSucceeded
    }
    
    func deleteDownload(for track: Track) {
        persistenceManager.deleteFile(for: track.id)
        
        // If this is the current track, update state
        if currentTrack?.id == track.id {
            isDownloaded = false
        }
    }
    
    func deleteAllDownloads(for concert: Concert) {
        for track in concert.tracks {
            deleteDownload(for: track)
        }
    }
    
    func isTrackDownloaded(_ track: Track) -> Bool {
        return persistenceManager.fileExists(for: track.id)
    }
    
    func isConcertDownloaded(_ concert: Concert) -> Bool {
        return concert.tracks.allSatisfy { isTrackDownloaded($0) }
    }
} 