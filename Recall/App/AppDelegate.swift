//
//  AppDelegate.swift
//  Recall
//
//  Manages NotchPanel, global hotkey, and clipboard monitoring lifecycle.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: NotchPanelController!
    private var container: DependencyContainer!
    private var clipboardViewModel: ClipboardViewModel!
    private var chatViewModel: ChatViewModel!
    private var mediaPlayerViewModel: MediaPlayerViewModel!
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var notificationObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon programmatically (backup for Info.plist)
        NSApp.setActivationPolicy(.accessory)

        // Setup dependency container
        container = DependencyContainer()
        clipboardViewModel = container.makeClipboardViewModel()
        chatViewModel = container.makeChatViewModel()
        mediaPlayerViewModel = container.makeMediaPlayerViewModel()

        // Setup panel controller
        panelController = NotchPanelController()

        // Build the content view with shared expansion state
        let contentView = NotchContentView(
            clipboardViewModel: clipboardViewModel,
            chatViewModel: chatViewModel,
            mediaViewModel: mediaPlayerViewModel,
            apiKeyStore: container.apiKeyStore,
            expansionState: panelController.expansionState
        )

        panelController.setupPanel(with: contentView)
        panelController.setupMouseTracking()
        panelController.setupClickOutsideHandler()

        // Connect panel collapse callback from clipboard ViewModel
        clipboardViewModel.onPanelShouldHide = { [weak self] in
            self?.panelController.collapse()
        }

        // Register global hotkey: ⌘ + Shift + V
        registerGlobalHotkey()

        // Listen for toggle notification from MenuBarExtra
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .toggleRecallPanel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.togglePanel()
        }

        // Start monitoring clipboard + media
        container.clipboardMonitor.start()
        mediaPlayerViewModel.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.clipboardMonitor.stop()
        mediaPlayerViewModel.stopMonitoring()

        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Panel Toggle

    private func togglePanel() {
        if panelController.isExpanded {
            panelController.collapse()
        } else {
            clipboardViewModel.loadItems()
            clipboardViewModel.searchQuery = ""
            clipboardViewModel.selectedIndex = clipboardViewModel.clipboardItems.isEmpty ? nil : 0
            panelController.expand()
        }
    }

    // MARK: - Global Hotkey

    private func registerGlobalHotkey() {
        // Global monitor (when app is not focused)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor (when app is focused)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // ⌘ + Shift + V
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .shift] && event.keyCode == 9 {
            DispatchQueue.main.async { [weak self] in
                self?.togglePanel()
            }
            return true
        }

        // Keyboard navigation only when panel is expanded
        guard panelController.isExpanded else { return false }

        switch event.keyCode {
        case 126: // Up arrow
            DispatchQueue.main.async { self.clipboardViewModel.moveSelectionUp() }
            return true
        case 125: // Down arrow
            DispatchQueue.main.async { self.clipboardViewModel.moveSelectionDown() }
            return true
        case 36: // Return
            if !clipboardViewModel.clipboardItems.isEmpty {
                if clipboardViewModel.selectedIndex == nil {
                    clipboardViewModel.selectedIndex = 0
                }
                DispatchQueue.main.async { self.clipboardViewModel.confirmSelection() }
                return true
            }
            return false
        case 53: // Escape
            DispatchQueue.main.async { self.panelController.collapse() }
            return true
        default:
            return false
        }
    }
}
