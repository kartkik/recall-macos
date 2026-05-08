//
//  NotchPanelController.swift
//  Recall
//
//  Manages the notch panel — positions over the hardware notch,
//  handles collapsed/expanded states, and mouse hover tracking.
//  Designed to match the Boring Notch aesthetic.
//

import AppKit
import Combine
import SwiftUI

final class NotchPanelController {
    // MARK: - Dimensions (Boring Notch style)

    /// Collapsed: small pill matching the hardware notch
    private let collapsedWidth: CGFloat = 230
    private let collapsedHeight: CGFloat = 34

    /// Expanded: wide panel growing from the notch
    private let expandedWidth: CGFloat = 900
    private let expandedHeight: CGFloat = 200

    // MARK: - State

    private var panel: NotchPanel?
    private var hostingView: NSHostingView<AnyView>?
    private(set) var isExpanded: Bool = false

    private var mouseGlobalMonitor: Any?
    private var mouseLocalMonitor: Any?
    private var clickOutsideMonitor: Any?
    private var collapseWorkItem: DispatchWorkItem?

    /// Observable state shared with the SwiftUI view
    var expansionState: NotchExpansionState

    // MARK: - Init

    init() {
        self.expansionState = NotchExpansionState()
    }

    // MARK: - Setup

    func setupPanel(with rootView: some View) {
        let collapsedFrame = calculateFrame(expanded: false)
        let panel = NotchPanel(contentRect: collapsedFrame)

        let wrappedView = AnyView(rootView)
        let hosting = NSHostingView(rootView: wrappedView)
        hosting.frame = NSRect(origin: .zero, size: collapsedFrame.size)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        self.hostingView = hosting
        self.panel = panel

        // Always show the collapsed notch pill
        panel.orderFrontRegardless()
    }

    // MARK: - Expand / Collapse

    func expand() {
        guard let panel = panel, !isExpanded else { return }

        collapseWorkItem?.cancel()
        isExpanded = true
        expansionState.isExpanded = true

        let expandedFrame = calculateFrame(expanded: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1) // ease-out-expo
            panel.animator().setFrame(expandedFrame, display: true)
        }

        panel.makeKey()
    }

    func collapse() {
        guard let panel = panel, isExpanded else { return }

        isExpanded = false
        expansionState.isExpanded = false

        let collapsedFrame = calculateFrame(expanded: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1) // ease-in-out
            panel.animator().setFrame(collapsedFrame, display: true)
        }

    }

    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    /// Collapse after a delay (for mouse leave)
    func collapseAfterDelay(_ delay: TimeInterval = 0.5) {
        collapseWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.collapse()
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelPendingCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    // MARK: - Mouse Hover Tracking

    func setupMouseTracking() {
        // Global: track mouse when app is not focused
        mouseGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMovement()
        }

        // Local: track mouse when panel has focus
        mouseLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMovement()
            return event
        }
    }

    private func handleMouseMovement() {
        let mouseLocation = NSEvent.mouseLocation
        let notchZone = calculateNotchHoverZone()
        let panelFrame = panel?.frame ?? .zero

        if notchZone.contains(mouseLocation) && !isExpanded {
            // Mouse entered the notch zone → expand
            cancelPendingCollapse()
            expand()
        } else if isExpanded {
            // Check if mouse is still within the panel bounds (with padding)
            let paddedFrame = panelFrame.insetBy(dx: -15, dy: -15)
            if !paddedFrame.contains(mouseLocation) {
                collapseAfterDelay(0.4)
            } else {
                cancelPendingCollapse()
            }
        }
    }

    /// The hover trigger zone — a thin strip right at the notch area
    private func calculateNotchHoverZone() -> NSRect {
        guard let screen = NSScreen.main else { return .zero }

        let screenFrame = screen.frame
        let zoneWidth: CGFloat = 260
        let zoneHeight: CGFloat = 15 // thin strip at the very top

        return NSRect(
            x: screenFrame.midX - (zoneWidth / 2),
            y: screenFrame.maxY - zoneHeight,
            width: zoneWidth,
            height: zoneHeight
        )
    }

    // MARK: - Click Outside

    func setupClickOutsideHandler() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isExpanded else { return }
            let mouseLocation = NSEvent.mouseLocation
            if let panelFrame = self.panel?.frame, !panelFrame.contains(mouseLocation) {
                self.collapse()
            }
        }
    }

    // MARK: - Frame Calculation

    private func calculateFrame(expanded: Bool) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 100, y: 100, width: expandedWidth, height: expandedHeight)
        }

        let screenFrame = screen.frame

        let width = expanded ? expandedWidth : collapsedWidth
        let height = expanded ? expandedHeight : collapsedHeight

        // Always centered horizontally, anchored at the very top of the screen
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - height

        return NSRect(x: x, y: y, width: width, height: height)
    }

    // MARK: - Cleanup

    deinit {
        if let m = mouseGlobalMonitor { NSEvent.removeMonitor(m) }
        if let m = mouseLocalMonitor { NSEvent.removeMonitor(m) }
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m) }
    }
}

// MARK: - Expansion State (Observable)

@Observable
final class NotchExpansionState {
    var isExpanded: Bool = false
}
