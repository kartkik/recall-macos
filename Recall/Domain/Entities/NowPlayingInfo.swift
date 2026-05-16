//
//  NowPlayingInfo.swift
//  Recall
//
//  Domain entity for currently playing media.
//

import AppKit
import Foundation

struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let artwork: NSImage?
    let isPlaying: Bool
    let appBundleID: String?
    let timestamp: Date

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentElapsedTime / duration, 1.0)
    }

    var currentElapsedTime: TimeInterval {
        guard isPlaying else { return elapsedTime }
        return elapsedTime + Date().timeIntervalSince(timestamp)
    }

    var formattedElapsed: String { formatTime(currentElapsedTime) }
    var formattedDuration: String { formatTime(duration) }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static let empty = NowPlayingInfo(
        title: "", artist: "", album: "",
        duration: 0, elapsedTime: 0,
        artwork: nil, isPlaying: false, 
        appBundleID: nil, timestamp: .distantPast
    )
}
