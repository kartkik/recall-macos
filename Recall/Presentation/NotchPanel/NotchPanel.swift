//
//  NotchPanel.swift
//  Recall
//
//  Custom NSPanel subclass for the floating notch UI.
//

import AppKit
import SwiftUI

final class NotchPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Panel behavior
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.hidesOnDeactivate = false

        // Allow the panel to become key for keyboard input (search, navigation)
        self.becomesKeyOnlyIfNeeded = false
        self.worksWhenModal = true
    }

    // Allow the panel to become key window for keyboard events
    override var canBecomeKey: Bool { true }

    // Never become main window — we're a utility panel
    override var canBecomeMain: Bool { false }
}
