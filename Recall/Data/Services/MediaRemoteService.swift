//
//  MediaRemoteService.swift
//  Recall
//
//  App Store–safe media service.
//  Uses NSWorkspace to detect the active media player and
//  NSAppleScript to query now-playing info and send playback commands.
//  Supports: Spotify, Apple Music, YouTube / SoundCloud in browsers.
//
//  Automation permission (-1743 / kAEEventNotPermitted):
//  Before every script we call AEDeterminePermissionToAutomateTarget so macOS
//  shows the one-time "Allow Recall to control X?" prompt.  Once the user
//  grants access the result is cached in-process to avoid repeat syscalls.
//

import AppKit
import Foundation

// MARK: - Automation Permission

/// Wraps `AEDeterminePermissionToAutomateTarget` so we only prompt once per
/// target app per process lifetime.  Results are cached; `.unknown` means the
/// syscall hasn't been made yet for that bundle ID.
private enum AutomationPermission {

    /// OSStatus values returned by AEDeterminePermissionToAutomateTarget.
    private static let errAEEventNotPermitted: OSStatus = -1743
    private static let errAEEventWouldRequireUserConsent: OSStatus = -1744

    /// In-process cache: bundleID → granted?
    private static var cache: [String: Bool] = [:]
    private static let lock = NSLock()

    /// Returns `true` if we already have (or just obtained) permission to
    /// send Apple Events to `bundleID`.  Pass `prompt: true` to trigger the
    /// system consent dialog when permission is not yet determined.
    @discardableResult
    static func request(for bundleID: String, prompt: Bool = true) -> Bool {
        lock.lock()
        if let cached = cache[bundleID] { lock.unlock(); return cached }
        lock.unlock()

        guard let app = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID).first
        else {
            print("[Recall] AEPermission: \(bundleID) not running — skipping")
            return false
        }

        // AEDeterminePermissionToAutomateTarget is available on 10.14+.
        // `askUserIfNeeded` controls whether the consent dialog is shown.
        var targetDesc = AEAddressDesc()
        let pid = app.processIdentifier

        let createResult = withUnsafePointer(to: pid) {
            AECreateDesc(
                DescType(typeKernelProcessID),
                $0,
                MemoryLayout.size(ofValue: pid),
                &targetDesc
            )
        }

        guard createResult == noErr else {
            print("[Recall] Failed to create AEAddressDesc for \(bundleID)")
            return false
        }

        defer {
            AEDisposeDesc(&targetDesc)
        }

        let status = AEDeterminePermissionToAutomateTarget(
            &targetDesc,
            typeWildCard,
            typeWildCard,
            prompt
        )

        let granted: Bool
        switch status {
        case noErr:
            granted = true
        case errAEEventNotPermitted:
            print("[Recall] AEPermission DENIED for \(bundleID)")
            granted = false
        case errAEEventWouldRequireUserConsent:
            // Prompt was suppressed (prompt=false).  Try again with dialog.
            print("[Recall] AEPermission: consent required for \(bundleID)")
            granted = false
        default:
            print("[Recall] AEPermission: unexpected OSStatus \(status) for \(bundleID)")
            granted = false
        }

        lock.lock()
        cache[bundleID] = granted
        lock.unlock()
        return granted
    }

    /// Evict the cached result (e.g. after the user changes privacy settings).
    static func resetCache(for bundleID: String) {
        lock.lock()
        cache.removeValue(forKey: bundleID)
        lock.unlock()
    }
}

// MARK: - Supported Player

import AppKit

 enum MediaPlayer: CaseIterable {

    case music
    case spotify
    case safari

    case brave
    case chrome
    case arc
    case edge
    case opera
    case vivaldi

    // MARK: - Detect Running Player

    static func detect(using workspace: NSWorkspace) -> MediaPlayer? {

        let running = Set(
            workspace.runningApplications
                .compactMap { $0.bundleIdentifier }
        )

        // Prefer dedicated media apps first
        if running.contains(MediaPlayer.music.bundleID) {
            return .music
        }

        if running.contains(MediaPlayer.spotify.bundleID) {
            return .spotify
        }

        // Then browsers
        return allCases.first {
            $0.isBrowser && running.contains($0.bundleID)
        }
    }

    // MARK: - Bundle Identifier

    var bundleID: String {

        switch self {

        case .music:
            return "com.apple.Music"

        case .spotify:
            return "com.spotify.client"

        case .safari:
            return "com.apple.Safari"

        case .brave:
            return "com.brave.Browser"

        case .chrome:
            return "com.google.Chrome"

        case .arc:
            return "company.thebrowser.Browser"

        case .edge:
            return "com.microsoft.edgemac"

        case .opera:
            return "com.operasoftware.Opera"

        case .vivaldi:
            return "com.vivaldi.Vivaldi"
        }
    }

    // MARK: - Display Name

    var appName: String {

        switch self {

        case .music:
            return "Music"

        case .spotify:
            return "Spotify"

        case .safari:
            return "Safari"

        case .brave:
            return "Brave Browser"

        case .chrome:
            return "Google Chrome"

        case .arc:
            return "Arc"

        case .edge:
            return "Microsoft Edge"

        case .opera:
            return "Opera"

        case .vivaldi:
            return "Vivaldi"
        }
    }

    // MARK: - Browser Check

    var isBrowser: Bool {

        switch self {

        case .safari,
             .brave,
             .chrome,
             .arc,
             .edge,
             .opera,
             .vivaldi:
            return true

        default:
            return false
        }
    }
}

// MARK: - MediaRemoteService

final class MediaRemoteService: @unchecked Sendable {

    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    // MARK: - Now Playing

    func fetchNowPlaying(completion: @escaping (NowPlayingInfo) -> Void) {
        guard let player = MediaPlayer.detect(using: workspace) else {
            print("[Recall] No supported media player is running.")
            completion(.empty)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let info = self.queryNowPlaying(for: player)
            DispatchQueue.main.async { completion(info) }
        }
    }

    private func queryNowPlaying(for player: MediaPlayer) -> NowPlayingInfo {
        switch player {

        case .music:
            return runScript("""
                tell application "Music"
                    if it is running and player state is not stopped then
                        set t to current track
                        return {name of t, artist of t, album of t, \
                                duration of t, player position, \
                                (player state is playing)}
                    end if
                end tell
                """,
                bundleID: player.bundleID,
                parse: parseTrackResult(bundleID: player.bundleID)
            )

        case .spotify:
            // Spotify reports duration in milliseconds.
            return runScript("""
                tell application "Spotify"
                    if it is running and player state is not stopped then
                        set t to current track
                        return {name of t, artist of t, album of t, \
                                (duration of t / 1000), player position, \
                                (player state is playing)}
                    end if
                end tell
                """,
                bundleID: player.bundleID,
                parse: parseTrackResult(bundleID: player.bundleID)
            )

        case .safari:
            return runScript("""
                tell application "Safari"
                    if it is running then
                        set t to name of current tab of window 1
                        return {t, "Safari", "", 0, 0, true}
                    end if
                end tell
                """,
                bundleID: player.bundleID,
                parse: parseBrowserResult(appName: "Safari", bundleID: player.bundleID)
            )

        case
             .brave,
             .chrome,
             .arc,
             .edge,
             .opera,
             .vivaldi:

            return runScript("""
                tell application "\(player.appName)"
                    if it is running then
                        set t to title of active tab of window 1
                        return {t, "\(player.appName)", "", 0, 0, true}
                    end if
                end tell
                """,
                bundleID: player.bundleID,
                parse: parseBrowserResult(
                    appName: player.appName,
                    bundleID: player.bundleID
                )
            )
        }
    }

    // MARK: - AppleScript Helpers

    /// Execute `source` targeting `bundleID`, requesting automation permission
    /// first.  Returns `.empty` if permission is denied or the script errors.
    private func runScript(
        _ source: String,
        bundleID: String,
        parse: (NSAppleEventDescriptor) -> NowPlayingInfo
    ) -> NowPlayingInfo {
        // 1. Ensure we have (or request) Automation permission.
        guard AutomationPermission.request(for: bundleID) else {
            print("[Recall] Skipping script — no Automation permission for \(bundleID)")
            return .empty
        }

        // 2. Compile and run.
        guard let script = NSAppleScript(source: source) else { return .empty }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        if let err = error {
            let code = err[NSAppleScript.errorNumber] as? Int ?? 0
            print("[Recall] AppleScript error: \(err)")

            // -1743 = permission revoked since we last checked → evict cache
            // so the next call re-prompts rather than silently failing forever.
            if code == -1743 { AutomationPermission.resetCache(for: bundleID) }
            return .empty
        }
        return parse(result)
    }

    /// Parser for Music / Spotify results: {title, artist, album, duration, elapsed, isPlaying}
    private func parseTrackResult(bundleID: String)
        -> (NSAppleEventDescriptor) -> NowPlayingInfo
    {
        return { desc in
            guard desc.numberOfItems >= 5 else { return .empty }
            let title     = desc.atIndex(1)?.stringValue  ?? ""
            let artist    = desc.atIndex(2)?.stringValue  ?? ""
            let album     = desc.atIndex(3)?.stringValue  ?? ""
            let duration  = desc.atIndex(4)?.doubleValue  ?? 0
            let elapsed   = desc.atIndex(5)?.doubleValue  ?? 0
            let isPlaying = (desc.atIndex(6)?.booleanValue ?? false)
            print("[Recall] \(title) — \(artist) | playing=\(isPlaying)")
            return NowPlayingInfo(
                title: title, artist: artist, album: album,
                duration: duration, elapsedTime: elapsed,
                artwork: nil, isPlaying: isPlaying, appBundleID: bundleID
            )
        }
    }

    /// Parser for browser tab title results.
    private func parseBrowserResult(appName: String, bundleID: String)
        -> (NSAppleEventDescriptor) -> NowPlayingInfo
    {
        return { desc in
            guard desc.numberOfItems >= 1 else { return .empty }
            let rawTitle = desc.atIndex(1)?.stringValue ?? ""
            let cleaned  = rawTitle
                .replacingOccurrences(of: " - YouTube",    with: "")
                .replacingOccurrences(of: " - SoundCloud", with: "")
            print("[Recall] Browser tab: \(cleaned) (\(appName))")
            return NowPlayingInfo(
                title: cleaned, artist: appName, album: "Web Media",
                duration: 0, elapsedTime: 0,
                artwork: nil, isPlaying: true, appBundleID: bundleID
            )
        }
    }

    // MARK: - Playback Controls
    //
    //  Each control targets whichever player is currently active so the
    //  command always reaches the right app.

    func togglePlayPause() { sendCommand(music: "playpause", spotify: "playpause") }
    func nextTrack()       { sendCommand(music: "next track", spotify: "next track") }
    func previousTrack()   { sendCommand(music: "previous track", spotify: "previous track") }
    func play()            { sendCommand(music: "play", spotify: "play") }
    func pause()           { sendCommand(music: "pause", spotify: "pause") }

    /// Send a command to whichever supported player is running.
    private func sendCommand(music musicCmd: String, spotify spotifyCmd: String) {
        guard let player = MediaPlayer.detect(using: workspace) else { return }

        let source: String
        switch player {
        case .music:
            source = "tell application \"Music\" to \(musicCmd)"
        case .spotify:
            source = "tell application \"Spotify\" to \(spotifyCmd)"
        default:
            // Browsers don't expose playback control via AppleScript.
            return
        }

        let bundleID = player.bundleID
        DispatchQueue.global(qos: .userInitiated).async {
            guard AutomationPermission.request(for: bundleID) else {
                print("[Recall] sendCommand blocked — no permission for \(bundleID)")
                return
            }
            var err: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&err)
            if let e = err {
                print("[Recall] Control script error: \(e)")
                let code = e[NSAppleScript.errorNumber] as? Int ?? 0
                if code == -1743 { AutomationPermission.resetCache(for: bundleID) }
            }
        }
    }
}
