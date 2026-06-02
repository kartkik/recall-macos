//
//  NotchTopBar.swift
//  Recall
//

import SwiftUI

struct NotchTopBar: View {
    @Binding var selectedTab: RecallTab
    var clipboardViewModel: ClipboardViewModel
    var chatViewModel: ChatViewModel
    var apiKeyStore: APIKeyStoreProtocol
    
    @State private var showSettings = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Tab icons
            HStack(spacing: 4) {
                ForEach(RecallTab.allCases, id: \.self) { tab in
                    tabIcon(tab)
                }
            }

            Spacer()

            // Center: Title or Provider selector
            centerContent

            Spacer()

            // Controls — fixed width so different tab controls don't shift layout
            HStack(spacing: 6) {
                if selectedTab == .clipboard {
                    clipboardControls
                } else if selectedTab == .chat {
                    chatControls
                } else if selectedTab == .calender {
                    calendarControls
                }
            }
            .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 4)
        .sheet(isPresented: $showSettings) {
            APIKeySettingsView(apiKeyStore: apiKeyStore)
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        if selectedTab == .chat {
            HStack(spacing: 4) {
                ForEach(AIProvider.allCases) { provider in
                    providerIcon(provider)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(.white.opacity(0.05)))
        } else {
            HStack(spacing: 5) {
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
                    .frame(width: 7, height: 7)

                Text("Recall")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var clipboardControls: some View {
        
        HStack{
            
            
            Button(action: { clipboardViewModel.clearAll() }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(.white.opacity(0.06)))
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "key.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 26, height: 26)
            }
        }
        
       
    }

    private var chatControls: some View {
        HStack(spacing: 6) {
            if !chatViewModel.messages.isEmpty {
                Button(action: { chatViewModel.clearChat() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "key.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarControls: some View {
        
        HStack{
            
            
            Button(action: { /* Jump to today */ }) {
                Text("Today")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.white.opacity(0.06))
                    )
            }
            
            Button(action: { showSettings = true }) {
                Image(systemName: "key.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(.white.opacity(0.06)))
            }
            .buttonStyle(.plain)

        }
    }

    private func tabIcon(_ tab: RecallTab) -> some View {
        let isSelected = selectedTab == tab

        return Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: tab.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.3))
                .frame(width: 30, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? .white.opacity(0.1) : .clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func providerIcon(_ provider: AIProvider) -> some View {
        let isSelected = chatViewModel.selectedProvider == provider
        return Button(action: { chatViewModel.selectedProvider = provider }) {
            Image(systemName: provider.iconName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.2))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? .white.opacity(0.1) : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}
