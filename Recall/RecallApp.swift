//
//  RecallApp.swift
//  Recall
//
//  Created by twixx  on 07/05/26.
//

import SwiftUI

@main
struct RecallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar extra for settings & quit
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            Image(systemName: "clipboard.fill")
        }
        .menuBarExtraStyle(.menu)

        // No WindowGroup — this is a menu bar / notch-only app
        Settings {
            EmptyView()
        }
    }
}

// MARK: - Menu Bar Content

struct MenuBarContentView: View {
    var body: some View {
        Button("Show Recall (⌘⇧V)") {
            NotificationCenter.default.post(name: .toggleRecallPanel, object: nil)
        }
        .keyboardShortcut("V", modifiers: [.command, .shift])

        Divider()

        Button("Quit Recall") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q", modifiers: .command)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleRecallPanel = Notification.Name("toggleRecallPanel")
}
