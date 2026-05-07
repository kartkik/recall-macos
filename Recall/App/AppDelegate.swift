//
//  AppDelegate.swift
//  Recall
//
//  Manages NotchPanel, global hotkey, and clipboard monitoring lifecycle.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: NotchPanelController!
    private var container: DependencyContainer!
    private var viewModel: ClipboardViewModel!
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon programmatically (backup for Info.plist)
        NSApp.setActivationPolicy(.accessory)

        // Setup dependency container
        container = DependencyContainer()
        viewModel = container.makeClipboardViewModel()

        // Setup panel
        panelController = NotchPanelController()
        let contentView = NotchContentView(viewModel: viewModel)
        panelController.setupPanel(with: contentView)
        panelController.setupClickOutsideHandler()

        // Connect panel hide callback
        viewModel.onPanelShouldHide = { [weak self] in
            self?.panelController.hide()
        }

        // Register global hotkey: ⌘ + Shift + V
        registerGlobalHotkey()

        // Start monitoring clipboard
        container.clipboardMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.clipboardMonitor.stop()

        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Global Hotkey

    private func registerGlobalHotkey() {
        // Global monitor (when app is not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor (when app is focused — e.g., panel is open)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // Consume the event
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // ⌘ + Shift + V
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .shift] && event.keyCode == 9 { // keyCode 9 = 'V'
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.panelController.isVisible {
                    self.panelController.hide()
                } else {
                    self.viewModel.loadItems()
                    self.viewModel.searchQuery = ""
                    self.viewModel.selectedIndex = nil
                    self.panelController.show()
                }
            }
            return true
        }
        return false
    }
}
