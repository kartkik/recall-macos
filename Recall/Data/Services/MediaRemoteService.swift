//
//  MediaRemoteService.swift
//  Recall
//
//  Interfaces with macOS MediaRemote private framework
//  to get now-playing info and send playback commands.
//  Works with Spotify, Apple Music, YouTube (browser), and any media player.
//

import AppKit
import Foundation

final class MediaRemoteService: @unchecked Sendable {
    // MARK: - Function Types

    private typealias MRNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRSendCommandFn = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool
    private typealias MRIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRRegisterForNotifFn = @convention(c) (DispatchQueue) -> Void

    // MARK: - Function Pointers

    private var getNowPlayingInfo: MRNowPlayingInfoFn?
    private var sendCommand: MRSendCommandFn?
    private var getIsPlaying: MRIsPlayingFn?
    private var registerForNotifications: MRRegisterForNotifFn?

    // MARK: - Info Keys (loaded from framework)

    private var kTitle: String?
    private var kArtist: String?
    private var kAlbum: String?
    private var kDuration: String?
    private var kElapsedTime: String?
    private var kArtworkData: String?
    private var kPlaybackRate: String?

    // MARK: - Commands

    private enum Command: UInt32 {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case stop = 3
        case nextTrack = 4
        case previousTrack = 5
    }

    // MARK: - Init

    init() {
        loadFramework()
    }

    private func loadFramework() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"

        guard let handle = dlopen(path, RTLD_NOW) else {
            print("[Recall] Failed to load MediaRemote framework")
            return
        }

        // Load function pointers
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(sym, to: MRNowPlayingInfoFn.self)
        }

        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(sym, to: MRSendCommandFn.self)
        }

        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlaying = unsafeBitCast(sym, to: MRIsPlayingFn.self)
        }

        if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerForNotifications = unsafeBitCast(sym, to: MRRegisterForNotifFn.self)
        }

        // Load info dictionary key constants
        kTitle = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoTitle")
        kArtist = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoArtist")
        kAlbum = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoAlbum")
        kDuration = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoDuration")
        kElapsedTime = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoElapsedTime")
        kArtworkData = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoArtworkData")
        kPlaybackRate = loadStringConstant(handle: handle, name: "kMRMediaRemoteNowPlayingInfoPlaybackRate")

        // Register for notifications so we get updates
        registerForNotifications?(DispatchQueue.main)

        print("[Recall] MediaRemote loaded — keys: title=\(kTitle ?? "nil"), artist=\(kArtist ?? "nil")")
    }

    private func loadStringConstant(handle: UnsafeMutableRawPointer, name: String) -> String? {
        guard let sym = dlsym(handle, name) else { return nil }
        let cfStr = sym.assumingMemoryBound(to: CFString.self).pointee
        return cfStr as String
    }

    // MARK: - Now Playing

    func fetchNowPlaying(completion: @escaping (NowPlayingInfo) -> Void) {
        guard let getNowPlayingInfo = getNowPlayingInfo else {
            print("[Recall] getNowPlayingInfo not available")
            completion(.empty)
            return
        }

        // Get playing state first, then info
        let playingFn = getIsPlaying
        let titleKey = kTitle
        let artistKey = kArtist
        let albumKey = kAlbum
        let durationKey = kDuration
        let elapsedKey = kElapsedTime
        let artworkKey = kArtworkData
        let playbackRateKey = kPlaybackRate

        let parseInfo: (Bool, [String: Any]) -> NowPlayingInfo = { isPlaying, info in
            // Debug: print available keys
            #if DEBUG
            if !info.isEmpty {
                let keys = info.keys.joined(separator: ", ")
                // Uncomment to debug: print("[Recall] NowPlaying keys: \(keys)")
            }
            #endif

            let title = (titleKey.flatMap { info[$0] as? String })
                ?? info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
                ?? ""

            let artist = (artistKey.flatMap { info[$0] as? String })
                ?? info["kMRMediaRemoteNowPlayingInfoArtist"] as? String
                ?? ""

            let album = (albumKey.flatMap { info[$0] as? String })
                ?? info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String
                ?? ""

            let duration = (durationKey.flatMap { info[$0] as? TimeInterval })
                ?? info["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval
                ?? 0

            let elapsed = (elapsedKey.flatMap { info[$0] as? TimeInterval })
                ?? info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval
                ?? 0

            var artwork: NSImage? = nil
            let artworkData = (artworkKey.flatMap { info[$0] as? Data })
                ?? info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            if let data = artworkData {
                artwork = NSImage(data: data)
            }

            // Check playback rate as a fallback for isPlaying
            let playbackRate = (playbackRateKey.flatMap { info[$0] as? Double })
                ?? info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double
                ?? 0

            let playing = isPlaying || playbackRate > 0

            return NowPlayingInfo(
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                elapsedTime: elapsed,
                artwork: artwork,
                isPlaying: playing,
                appBundleID: nil
            )
        }

        if let playingFn = playingFn {
            playingFn(DispatchQueue.main) { isPlaying in
                getNowPlayingInfo(DispatchQueue.main) { info in
                    completion(parseInfo(isPlaying, info))
                }
            }
        } else {
            // Fallback: use playback rate to determine playing state
            getNowPlayingInfo(DispatchQueue.main) { info in
                completion(parseInfo(false, info))
            }
        }
    }

    // MARK: - Controls

    func togglePlayPause() {
        _ = sendCommand?(Command.togglePlayPause.rawValue, nil)
    }

    func nextTrack() {
        _ = sendCommand?(Command.nextTrack.rawValue, nil)
    }

    func previousTrack() {
        _ = sendCommand?(Command.previousTrack.rawValue, nil)
    }

    func play() {
        _ = sendCommand?(Command.play.rawValue, nil)
    }

    func pause() {
        _ = sendCommand?(Command.pause.rawValue, nil)
    }
}
