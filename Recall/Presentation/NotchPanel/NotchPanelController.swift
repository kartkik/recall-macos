//
//  NotchPanelController.swift
//  Recall
//
//  Manages panel positioning, show/hide, and hosting SwiftUI content.
//

import AppKit
import SwiftUI

final class NotchPanelController {
    private var panel: NotchPanel?
    private let panelWidth: CGFloat = 360
    private let panelMaxHeight: CGFloat = 520
    private let collapsedWidth: CGFloat = 200
    private let collapsedHeight: CGFloat = 32

    private(set) var isVisible: Bool = false

    // MARK: - Setup

    func setupPanel(with rootView: some View) {
        let contentRect = calculatePanelFrame(expanded: false)
        let panel = NotchPanel(contentRect: contentRect)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = panel.contentView?.bounds ?? contentRect
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)

        self.panel = panel
    }

    // MARK: - Show / Hide

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let panel = panel else { return }

        let expandedFrame = calculatePanelFrame(expanded: true)
        panel.setFrame(expandedFrame, display: true, animate: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        isVisible = true

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let panel = panel else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
        })
    }

    // MARK: - Positioning

    private func calculatePanelFrame(expanded: Bool) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: panelWidth, height: panelMaxHeight)
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY

        let width = expanded ? panelWidth : collapsedWidth
        let height = expanded ? panelMaxHeight : collapsedHeight

        // Center horizontally on screen, position just below menu bar
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - menuBarHeight - height

        return NSRect(x: x, y: y, width: width, height: height)
    }

    // MARK: - Click Outside Detection

    func setupClickOutsideHandler() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            // If click is outside the panel, hide it
            if let panel = self.panel {
                let clickLocation = event.locationInWindow
                let panelFrame = panel.frame
                let screenPoint = NSEvent.mouseLocation
                if !panelFrame.contains(screenPoint) {
                    self.hide()
                }
            }
        }
    }
}
