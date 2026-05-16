//
//  CollapsedNotchView.swift
//  Recall
//

import SwiftUI

struct CollapsedNotchView: View {
    var clipboardViewModel: ClipboardViewModel
    var mediaViewModel: MediaPlayerViewModel
    var isHovered: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Media support commented out as requested
            /*
            if mediaViewModel.hasMedia {
                HStack(spacing: 6) {
                    if let artwork = mediaViewModel.nowPlaying.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 18, height: 18)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.1)))
                    }

                    VStack(alignment: .leading, spacing: -1) {
                        Text(mediaViewModel.nowPlaying.title)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                        Text(mediaViewModel.nowPlaying.artist)
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 80, alignment: .leading)

                    NowPlayingIndicator(isPlaying: mediaViewModel.nowPlaying.isPlaying)
                }
            } else {
            */
                // Default Recall Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.39, green: 0.40, blue: 0.95),
                                    Color(red: 0.55, green: 0.36, blue: 0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)

                    Text("Recall")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(isHovered ? 0.9 : 0.6))
                }
            /*
            }
            */

            if !clipboardViewModel.clipboardItems.isEmpty {
                Text("·  \(clipboardViewModel.clipboardItems.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(isHovered ? 0.5 : 0.3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
