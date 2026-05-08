//
//  MediaPlayerViewModel.swift
//  Recall
//
//  ViewModel for now-playing media detection and controls.
//

import AppKit
import Foundation
import SwiftUI

@Observable
final class MediaPlayerViewModel {
    // MARK: - State

    var nowPlaying: NowPlayingInfo = .empty
    var hasMedia: Bool = false

    // MARK: - Dependencies

    private let mediaService: MediaRemoteService
    private var pollTimer: Timer?

    // MARK: - Init

    init(mediaService: MediaRemoteService) {
        self.mediaService = mediaService
    }

    // MARK: - Lifecycle

    func startMonitoring() {
        // Poll every 1 second for now-playing updates
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        // Immediate first fetch
        refresh()
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Actions

    func togglePlayPause() {
        mediaService.togglePlayPause()
        // Refresh after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.refresh()
        }
    }

    func nextTrack() {
        mediaService.nextTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }

    func previousTrack() {
        mediaService.previousTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - Private

    private func refresh() {
        mediaService.fetchNowPlaying { [weak self] info in
            guard let self else { return }
            self.nowPlaying = info
            self.hasMedia = !info.title.isEmpty
        }
    }
}
