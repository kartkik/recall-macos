//
//  MediaPlayerViewModel.swift
//  Recall
//

import AppKit
import Foundation
import SwiftUI

@Observable
@MainActor
final class MediaPlayerViewModel {

    // MARK: - Published State

    var nowPlaying: NowPlayingInfo = .empty
    var hasMedia: Bool = false

    /// Current detected player
    var currentPlayer: MediaPlayer?

    /// Helpful for debugging / UI
    var currentPlayerName: String {
        currentPlayer?.appName ?? "No Media"
    }

    // MARK: - Dependencies

    private let mediaService: MediaRemoteService
    private let workspace: NSWorkspace

    // MARK: - Timers

    private var pollTimer: Timer?
    private var uiTimer: Timer?

    // MARK: - Init

    init(
        mediaService: MediaRemoteService,
        workspace: NSWorkspace = .shared
    ) {
        self.mediaService = mediaService
        self.workspace = workspace
    }

    // MARK: - Lifecycle

    func startMonitoring() {
        stopMonitoring()

        // Immediate fetch
        refresh()

        // Poll system every 2 seconds (AppleScript is slow, so we don't want to over-poll)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        // Update UI every 0.1s for smooth progress bar
        uiTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // No-op refresh to trigger SwiftUI observation if needed, 
            // but we'll use a dummy state to be sure.
            Task { @MainActor in
                self?.objectWillChange()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        uiTimer?.invalidate()
        pollTimer = nil
        uiTimer = nil
    }

    var lastUIUpdate: Date = Date()

    private func objectWillChange() {
        lastUIUpdate = Date()
    }
    
    var smoothProgress: Double {
        _ = lastUIUpdate
        return nowPlaying.progress
    }

    var smoothElapsed: String {
        _ = lastUIUpdate
        return nowPlaying.formattedElapsed
    }

    // MARK: - Playback Controls

    func togglePlayPause() {

        guard hasMedia else { return }

        mediaService.togglePlayPause()

        refreshAfterDelay(0.2)
    }

    func nextTrack() {

        guard hasMedia else { return }

        mediaService.nextTrack()

        refreshAfterDelay(0.3)
    }

    func previousTrack() {

        guard hasMedia else { return }

        mediaService.previousTrack()

        refreshAfterDelay(0.3)
    }

    // MARK: - Refresh

    private func refresh() {

        // Detect current player
        currentPlayer = MediaPlayer.detect(using: workspace)

        mediaService.fetchNowPlaying { [weak self] info in

            guard let self else { return }

            self.nowPlaying = info
            self.hasMedia = !info.title.isEmpty

            // Helpful logs
            if self.hasMedia {
                print(
                    "[Recall] Now Playing: \(info.title) " +
                    "(\(self.currentPlayerName))"
                )
            }
        }
    }

    // MARK: - Helpers

    private func refreshAfterDelay(_ delay: Double) {

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) { [weak self] in

            self?.refresh()
        }
    }
}
