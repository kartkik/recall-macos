//
//  NotchShape.swift
//  Recall
//
//  Custom shape mimicking the MacBook notch geometry.
//

import SwiftUI

struct NotchShape: Shape {
    /// Controls the notch curve radius. Animatable.
    var notchRadius: CGFloat = 12

    var animatableData: CGFloat {
        get { notchRadius }
        set { notchRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = notchRadius
        let topInset: CGFloat = 0

        // Start from top-left with rounded corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius + topInset))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + topInset),
            control: CGPoint(x: rect.minX, y: rect.minY + topInset)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + topInset))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius + topInset),
            control: CGPoint(x: rect.maxX, y: rect.minY + topInset)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        path.closeSubpath()
        return path
    }
}
