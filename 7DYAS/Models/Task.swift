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
    var type: TaskType // 计划/每日循环/日志
    var cycle: TaskCycle // 日/周/月/年
    var dateRange: TaskDateRange? // 多日期支持
    var atItems: [String] // @事项
    var completedTime: Date? // 完成时间
    var duration: TimeInterval? // 完成耗时
    var isDeferred: Bool // 是否延期
    var originalTaskId: UUID? // 原始任务ID，用于防止重复顺延
    
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
    
    init(title: String, content: String = "", tags: [String] = [], dueDate: Date? = nil, priority: TaskPriority = .medium, type: TaskType = .plan, cycle: TaskCycle = .day, dateRange: TaskDateRange? = nil, atItems: [String] = [], images: [String] = [], createdDate: Date = Date()) {
        self.title = title
        self.content = content
        self.tags = tags
        self.createdDate = createdDate
        self.dueDate = dueDate
        self.isCompleted = false
        self.priority = priority
        self.images = images
        self.type = type
        self.cycle = cycle
        self.dateRange = dateRange
        self.atItems = atItems
        self.completedTime = nil
        self.duration = nil
        self.isDeferred = false
        self.originalTaskId = nil
    }
}

// 任务类型枚举
enum TaskType: String, CaseIterable, Codable {
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

// 新增：任务周期类型
enum TaskCycle: String, CaseIterable, Codable {
    case day = "日"
    case week = "周"
    case month = "月"
    case year = "年"
}

// 新增：任务显示在哪些日期（如多选周一/周二等）
struct TaskDateRange: Codable, Hashable {
    var cycle: TaskCycle
    var selectedDays: [Int] // 日: [1], 周: [1,2], 月: [1,2,3], 年: [1,2,...12]
}
