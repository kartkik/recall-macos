//
//  MediaPlayerView.swift
//  Recall
//
//  Dynamic Island style media player with album art and controls.
//

import SwiftUI

struct MediaPlayerView: View {
    var viewModel: MediaPlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            // Album artwork
            albumArt

            // Track info + progress
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.nowPlaying.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                Text(viewModel.nowPlaying.artist)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.39, green: 0.40, blue: 0.95),
                                        Color(red: 0.55, green: 0.36, blue: 0.96)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * viewModel.nowPlaying.progress)
                    }
                }
                .frame(height: 3)

                // Time
                HStack {
                    Text(viewModel.nowPlaying.formattedElapsed)
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text(viewModel.nowPlaying.formattedDuration)
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)

            // Playback controls
            playbackControls
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    // MARK: - Album Art

    private var albumArt: some View {
        Group {
            if let artwork = viewModel.nowPlaying.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.3),
                            Color(red: 0.15, green: 0.15, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 8) {
            // Previous
            Button(action: { viewModel.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            // Play/Pause
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)

            // Next
            Button(action: { viewModel.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Compact (collapsed) indicator

struct NowPlayingIndicator: View {
    let isPlaying: Bool

    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.39, green: 0.40, blue: 0.95),
                                Color(red: 0.55, green: 0.36, blue: 0.96)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 2.5, height: animating && isPlaying ? CGFloat.random(in: 4...12) : 3)
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: Double.random(in: 0.3...0.6))
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1)
                            : .easeOut(duration: 0.3),
                        value: animating
                    )
            }
        }
        .frame(height: 12)
        .onAppear { animating = true }
        .onChange(of: isPlaying) { _, playing in
            animating = playing
        }
    }
}
