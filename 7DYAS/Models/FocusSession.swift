//
//  FocusSession.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import SwiftUI

struct FocusSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var tags: [String]
    var relatedEvents: [String] // 关联的事件列表
    var relatedTask: UUID? // 关联的任务ID
    var notes: String
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "\(seconds)秒"
        }
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: startTime)
    }
    
    init(title: String, startTime: Date = Date(), duration: TimeInterval = 0, tags: [String] = [], relatedEvents: [String] = [], relatedTask: UUID? = nil, notes: String = "") {
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.endTime = startTime.addingTimeInterval(duration)
        self.tags = tags
        self.relatedEvents = relatedEvents
        self.relatedTask = relatedTask
        self.notes = notes
    }
    
    init(id: UUID, title: String, startTime: Date, duration: TimeInterval, tags: [String] = [], relatedEvents: [String] = [], notes: String = "", relatedTask: UUID? = nil) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.endTime = startTime.addingTimeInterval(duration)
        self.tags = tags
        self.relatedEvents = relatedEvents
        self.notes = notes
        self.relatedTask = relatedTask
    }
    
    // MARK: - Equatable
    static func == (lhs: FocusSession, rhs: FocusSession) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.duration == rhs.duration &&
               lhs.tags == rhs.tags &&
               lhs.relatedEvents == rhs.relatedEvents &&
               lhs.relatedTask == rhs.relatedTask &&
               lhs.notes == rhs.notes
    }
}

// 专注会话状态
enum FocusSessionState: String {
    case idle = "准备中"
    case running = "专注中"
    case paused = "已暂停"
    case completed = "已完成"
}
