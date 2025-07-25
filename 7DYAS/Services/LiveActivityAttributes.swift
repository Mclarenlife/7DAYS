//
//  LiveActivityAttributes.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/25.
//

import Foundation
import ActivityKit

// 灵动岛和LiveActivity的数据模型
struct FocusSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 动态更新的状态
        public var elapsedTime: TimeInterval
        public var sessionState: String // 专注状态（运行中/暂停）
        public var remainingTime: TimeInterval? // 可选的剩余时间
        
        public init(elapsedTime: TimeInterval, sessionState: String, remainingTime: TimeInterval? = nil) {
            self.elapsedTime = elapsedTime
            self.sessionState = sessionState
            self.remainingTime = remainingTime
        }
    }

    // 固定的会话信息
    public var title: String
    public var startTime: Date
    public var tags: [String]
    
    public init(title: String, startTime: Date, tags: [String]) {
        self.title = title
        self.startTime = startTime
        self.tags = tags
    }
} 