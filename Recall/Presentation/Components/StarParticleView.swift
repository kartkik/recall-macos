//
//  StarParticleView.swift
//  Recall
//
//  Sparkle/star particle animation effect triggered on hover.
//

import SwiftUI

// MARK: - Star Particle

struct StarParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var scale: CGFloat
}

// MARK: - Star Particle View

struct StarParticleView: View {
    let isActive: Bool
    let particleCount: Int
    let bounds: CGSize

    @State private var particles: [StarParticle] = []
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                StarShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.50, blue: 1.0),
                                Color(red: 0.75, green: 0.65, blue: 1.0),
                                .white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                startEmitting()
            } else {
                stopEmitting()
            }
        }
    }

    // MARK: - Emitter

    private func startEmitting() {
        // Spawn initial burst
        spawnBurst(count: particleCount)

        // Keep spawning
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            spawnBurst(count: 2)
            cleanupParticles()
        }
    }

    private func stopEmitting() {
        timer?.invalidate()
        timer = nil

        // Fade out remaining particles
        withAnimation(.easeOut(duration: 0.5)) {
            particles = particles.map { p in
                var updated = p
                updated.opacity = 0
                updated.scale = 0.1
                return updated
            }
        }

        // Clean up after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particles.removeAll()
        }
    }

    private func spawnBurst(count: Int) {
        for _ in 0..<count {
            let particle = StarParticle(
                x: CGFloat.random(in: 10...(bounds.width - 10)),
                y: CGFloat.random(in: 2...(bounds.height - 2)),
                size: CGFloat.random(in: 4...10),
                opacity: 0,
                rotation: Double.random(in: 0...360),
                scale: 0.1
            )
            particles.append(particle)

            // Animate in
            let idx = particles.count - 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                particles[idx].opacity = Double.random(in: 0.4...0.9)
                particles[idx].scale = CGFloat.random(in: 0.5...1.2)
                particles[idx].rotation += Double.random(in: -45...45)
            }

            // Animate out
            let lifetime = Double.random(in: 0.6...1.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
                if let fadeIdx = particles.firstIndex(where: { $0.id == particle.id }) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        particles[fadeIdx].opacity = 0
                        particles[fadeIdx].scale = 0.1
                        particles[fadeIdx].y -= 5
                    }
                }
            }
        }
    }

    private func cleanupParticles() {
        particles.removeAll { $0.opacity <= 0.01 }
        // Cap max particles
        if particles.count > 20 {
            particles.removeFirst(particles.count - 20)
        }
    }
}

// MARK: - 4-Point Star Shape

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.35

        var path = Path()
        let points = 4
        let angleStep = .pi / Double(points)

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleStep - .pi / 2

            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
