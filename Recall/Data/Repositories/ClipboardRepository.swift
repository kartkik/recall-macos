//
//  ClipboardRepository.swift
//  Recall
//
//  Concrete implementation of ClipboardRepositoryProtocol using SwiftData.
//

import Foundation
import SwiftData
import AppKit

final class ClipboardRepository: ClipboardRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            sortBy: [
                SortDescriptor(\ClipboardItemModel.timestamp, order: .reverse)
            ]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return ClipboardItemMapper
                .toEntities(models)
                .sorted { lhs, rhs in
                    if lhs.isPinned != rhs.isPinned {
                        return lhs.isPinned && !rhs.isPinned
                    }
                    return lhs.timestamp > rhs.timestamp
                }
        } catch {
            print("[Recall] Failed to fetch clipboard items: \(error)")
            return []
        }
    }

    func save(_ item: ClipboardItem) {
        // Check for duplicates — skip if the same content was just saved
        let content = item.content
        var descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate { $0.content == content },
            sortBy: [SortDescriptor(\ClipboardItemModel.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            // Update timestamp of existing item instead of creating a duplicate
            existing.timestamp = Date()
            existing.sourceAppName = item.sourceAppName
            existing.sourceAppBundleID = item.sourceAppBundleID
        } else {
            let model = ClipboardItemMapper.toModel(item)
            modelContext.insert(model)
        }

        saveContext()
    }

    func delete(_ item: ClipboardItem) {
        let targetID = item.id
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let model = try? modelContext.fetch(descriptor).first {
            modelContext.delete(model)
            saveContext()
        }
    }

    func search(query: String) -> [ClipboardItem] {
        let lowercasedQuery = query.lowercased()
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate {
                $0.content.localizedStandardContains(lowercasedQuery)
            },
            sortBy: [
                SortDescriptor(\ClipboardItemModel.timestamp, order: .reverse)
            ]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return ClipboardItemMapper
                .toEntities(models)
                .sorted { lhs, rhs in
                    if lhs.isPinned != rhs.isPinned {
                        return lhs.isPinned && !rhs.isPinned
                    }
                    return lhs.timestamp > rhs.timestamp
                }
        } catch {
            print("[Recall] Failed to search clipboard items: \(error)")
            return []
        }
    }

    func togglePin(_ item: ClipboardItem) {
        let targetID = item.id
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let model = try? modelContext.fetch(descriptor).first {
            model.isPinned.toggle()
            saveContext()
        }
    }
    
    func copyItem(_ item : ClipboardItem){
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
    }

    func clearAll() {
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate { $0.isPinned == false }
        )
        if let models = try? modelContext.fetch(descriptor) {
            for model in models {
                modelContext.delete(model)
            }
            saveContext()
        }
    }

    func count() -> Int {
        let descriptor = FetchDescriptor<ClipboardItemModel>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func trimToLimit(_ limit: Int) {
        let currentCount = count()
        guard currentCount > limit else { return }

        // Fetch oldest unpinned items beyond the limit
        let descriptor = FetchDescriptor<ClipboardItemModel>(
            predicate: #Predicate { $0.isPinned == false },
            sortBy: [SortDescriptor(\ClipboardItemModel.timestamp, order: .forward)]
        )
        if let models = try? modelContext.fetch(descriptor) {
            let excess = currentCount - limit
            for model in models.prefix(excess) {
                modelContext.delete(model)
            }
            saveContext()
        }
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("[Recall] Failed to save context: \(error)")
        }
    }
}
