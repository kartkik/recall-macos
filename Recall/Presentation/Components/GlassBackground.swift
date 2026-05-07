//
//  GlassBackground.swift
//  Recall
//
//  Glassmorphism background using NSVisualEffectView.
//

import SwiftUI

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    }
}
