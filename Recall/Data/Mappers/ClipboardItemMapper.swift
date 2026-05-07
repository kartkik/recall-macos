//
//  ClipboardItemMapper.swift
//  Recall
//
//  Maps between SwiftData models and domain entities.
//

import Foundation

enum ClipboardItemMapper {

    // MARK: - Model → Entity

    static func toEntity(_ model: ClipboardItemModel) -> ClipboardItem {
        ClipboardItem(
            id: model.id,
            content: model.content,
            imageData: model.imageData,
            contentType: model.contentType,
            timestamp: model.timestamp,
            isPinned: model.isPinned,
            sourceAppName: model.sourceAppName,
            sourceAppBundleID: model.sourceAppBundleID
        )
    }

    // MARK: - Entity → Model

    static func toModel(_ entity: ClipboardItem) -> ClipboardItemModel {
        ClipboardItemModel(
            id: entity.id,
            content: entity.content,
            imageData: entity.imageData,
            contentTypeRaw: entity.contentType.rawValue,
            timestamp: entity.timestamp,
            isPinned: entity.isPinned,
            sourceAppName: entity.sourceAppName,
            sourceAppBundleID: entity.sourceAppBundleID
        )
    }

    // MARK: - Batch

    static func toEntities(_ models: [ClipboardItemModel]) -> [ClipboardItem] {
        models.map { toEntity($0) }
    }
}
