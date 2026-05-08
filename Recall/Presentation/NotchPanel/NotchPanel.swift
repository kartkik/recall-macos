//
//  NotchPanel.swift
//  Recall
//
//  Custom NSPanel subclass for the notch overlay.
//  Always floats above everything, borderless, transparent.
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

        // Float above everything (including menu bar)
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.worksWhenModal = true
        self.ignoresMouseEvents = false

        // Allow mouse tracking through the panel
        self.acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
