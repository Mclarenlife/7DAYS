//
//  Tag.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import SwiftUI

struct Tag: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var color: TagColor
    var createdDate: Date
    var usageCount: Int // 使用次数
    
    enum TagColor: String, CaseIterable, Codable {
        case blue = "蓝色"
        case green = "绿色"
        case orange = "橙色"
        case red = "红色"
        case purple = "紫色"
        case pink = "粉色"
        case yellow = "黄色"
        case cyan = "青色"
        case indigo = "靛色"
        case gray = "灰色"
        
        var swiftUIColor: Color {
            switch self {
            case .blue:
                return .blue
            case .green:
                return .green
            case .orange:
                return .orange
            case .red:
                return .red
            case .purple:
                return .purple
            case .pink:
                return .pink
            case .yellow:
                return .yellow
            case .cyan:
                return .cyan
            case .indigo:
                return .indigo
            case .gray:
                return .gray
            }
        }
    }
    
    init(name: String, color: TagColor = .blue) {
        self.name = name
        self.color = color
        self.createdDate = Date()
        self.usageCount = 0
    }
    
    mutating func incrementUsage() {
        usageCount += 1
    }
}

// 临时想法模型
struct TemporaryIdea: Identifiable, Codable {
    var id = UUID()
    var content: String
    var tags: [String]
    var createdDate: Date
    var isArchived: Bool
    var priority: Task.TaskPriority
    
    init(content: String, tags: [String] = [], priority: Task.TaskPriority = .medium) {
        self.content = content
        self.tags = tags
        self.createdDate = Date()
        self.isArchived = false
        self.priority = priority
    }
}
