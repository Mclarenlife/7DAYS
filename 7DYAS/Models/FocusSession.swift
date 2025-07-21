//
//  FocusSession.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import SwiftUI

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var tags: [String]
    var relatedTask: UUID? // 关联的任务ID
    var notes: String
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
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
    
    init(title: String, startTime: Date = Date(), duration: TimeInterval = 0, tags: [String] = [], relatedTask: UUID? = nil, notes: String = "") {
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.endTime = startTime.addingTimeInterval(duration)
        self.tags = tags
        self.relatedTask = relatedTask
        self.notes = notes
    }
}

// 专注会话状态
enum FocusSessionState {
    case idle
    case running
    case paused
    case completed
}
