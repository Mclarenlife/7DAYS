//
//  _DAYS_LiveActivityLiveActivity.swift
//  7DAYS_LiveActivity
//
//  Created by Mclarenlife on 2025/7/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// 在扩展中直接定义所需的类型
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

struct _DAYS_LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            // 锁屏/通知横幅UI
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        
                    Spacer()
                    
                    Text(context.state.sessionState)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(context.state.sessionState == "专注中" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(context.state.sessionState == "专注中" ? .green : .orange)
                        .clipShape(Capsule())
                }
                
                HStack {
                    Text(formattedTime(context.state.elapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    let tags = context.attributes.tags.prefix(2)
                    if !tags.isEmpty {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                if let remainingTime = context.state.remainingTime, remainingTime > 0 {
                    HStack {
                        Spacer()
                        Text("剩余: \(formattedTime(remainingTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color.orange)

        } dynamicIsland: { context in
            DynamicIsland {
                // 展开的灵动岛UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(context.state.sessionState)
                            .font(.caption)
                            .foregroundColor(context.state.sessionState == "专注中" ? .green : .orange)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if let remainingTime = context.state.remainingTime, remainingTime > 0 {
                            Text("剩余")
                                .font(.caption2)
                            Text(formattedTime(remainingTime))
                                .font(.caption)
                                .monospacedDigit()
                        } else {
                            Text("专注中")
                                .font(.caption)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // 左侧显示标签
                        if !context.attributes.tags.isEmpty {
                            HStack {
                                ForEach(context.attributes.tags.prefix(2), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧显示已经专注的时间
                        VStack(alignment: .trailing) {
                            Text("已专注")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formattedTime(context.state.elapsedTime))
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } compactLeading: {
                // 紧凑区域左侧内容
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // 紧凑区域右侧显示计时时间
                Text(formattedTime(context.state.elapsedTime))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.orange)
            } minimal: {
                // 最小模式显示计时图标
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            }
        }
    }
    
    // 格式化时间的辅助函数
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// 预览扩展
extension FocusSessionAttributes {
    fileprivate static var preview: FocusSessionAttributes {
        FocusSessionAttributes(
            title: "学习Swift编程",
            startTime: Date(),
            tags: ["学习", "编程"]
        )
    }
}

extension FocusSessionAttributes.ContentState {
    fileprivate static var running: FocusSessionAttributes.ContentState {
        FocusSessionAttributes.ContentState(
            elapsedTime: 1825, // 30分25秒
            sessionState: "专注中",
            remainingTime: 3600 // 1小时
        )
    }
     
    fileprivate static var paused: FocusSessionAttributes.ContentState {
        FocusSessionAttributes.ContentState(
            elapsedTime: 900, // 15分钟
            sessionState: "已暂停",
            remainingTime: nil
        )
    }
}

#Preview("Notification", as: .content, using: FocusSessionAttributes.preview) {
   _DAYS_LiveActivityLiveActivity()
} contentStates: {
    FocusSessionAttributes.ContentState.running
    FocusSessionAttributes.ContentState.paused
}
