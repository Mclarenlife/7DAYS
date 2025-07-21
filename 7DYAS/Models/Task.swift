//
//  Task.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var tags: [String]
    var createdDate: Date
    var dueDate: Date?
    var isCompleted: Bool
    var priority: TaskPriority
    var images: [String] // 图片文件名数组
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case urgent = "紧急"
        
        var color: Color {
            switch self {
            case .low:
                return .green
            case .medium:
                return .blue
            case .high:
                return .orange
            case .urgent:
                return .red
            }
        }
    }
    
    init(title: String, content: String = "", tags: [String] = [], dueDate: Date? = nil, priority: TaskPriority = .medium) {
        self.title = title
        self.content = content
        self.tags = tags
        self.createdDate = Date()
        self.dueDate = dueDate
        self.isCompleted = false
        self.priority = priority
        self.images = []
    }
}

// 任务类型枚举
enum TaskType: String, CaseIterable {
    case plan = "计划"
    case dailyRoutine = "每日循环"
    case journal = "日志"
    
    var icon: String {
        switch self {
        case .plan:
            return "list.bullet"
        case .dailyRoutine:
            return "repeat"
        case .journal:
            return "book"
        }
    }
}
