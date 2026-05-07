//
//  ClipboardMonitor.swift
//  Recall
//
//  Monitors the system pasteboard for changes and captures new clipboard items.
//

import AppKit
import Combine
import Foundation

final class ClipboardMonitor: @unchecked Sendable {
    private let pasteboardService: PasteboardServiceProtocol
    private var lastChangeCount: Int
    private var timer: Timer?
    private let pollInterval: TimeInterval

    /// Publisher that emits new clipboard items when detected.
    let onNewItem = PassthroughSubject<ClipboardItem, Never>()

    /// Set to true to temporarily ignore the next pasteboard change
    /// (e.g., when the app itself writes to the pasteboard).
    var ignoreNextChange: Bool = false

    init(
        pasteboardService: PasteboardServiceProtocol,
        pollInterval: TimeInterval = 0.5
    ) {
        self.pasteboardService = pasteboardService
        self.lastChangeCount = pasteboardService.changeCount()
        self.pollInterval = pollInterval
    }

    // MARK: - Lifecycle

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        // Ensure timer fires even during tracking loops (e.g., when menus are open)
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func checkForChanges() {
        let currentCount = pasteboardService.changeCount()
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip if the app itself caused this change
        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        // Determine content type and capture
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let sourceAppName = frontmostApp?.localizedName
        let sourceAppBundleID = frontmostApp?.bundleIdentifier

        if let text = pasteboardService.currentTextContent(),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ClipboardItem(
                content: text,
                contentType: .text,
                sourceAppName: sourceAppName,
                sourceAppBundleID: sourceAppBundleID
            )
            onNewItem.send(item)
        } else if let imageData = pasteboardService.currentImageData() {
            let item = ClipboardItem(
                content: "",
                imageData: imageData,
                contentType: .image,
                sourceAppName: sourceAppName,
                sourceAppBundleID: sourceAppBundleID
            )
            onNewItem.send(item)
        }
    }

    deinit {
        stop()
    }
}
