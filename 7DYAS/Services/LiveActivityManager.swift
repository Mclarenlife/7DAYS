//
//  LiveActivityManager.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/25.
//

import Foundation
import ActivityKit
import SwiftUI
import OSLog

// 不需要额外的导入，FocusSessionAttributes将直接在项目中可见

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private let logger = Logger(subsystem: "com.mclarenlife.7DYAS", category: "LiveActivity")
    
    @Published private(set) var currentActivity: Activity<FocusSessionAttributes>?
    
    private init() {
        // 检查系统是否支持LiveActivity
        if #available(iOS 16.1, *) {
            logger.debug("系统支持LiveActivity")
        } else {
            logger.debug("系统不支持LiveActivity")
        }
    }
    
    // 开始一个新的LiveActivity
    func startLiveActivity(session: FocusSession) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.error("LiveActivity未被授权")
            return
        }
        
        // 如果当前存在活动，先结束它
        await endLiveActivity()
        
        // 准备初始状态
        let initialState = FocusSessionAttributes.ContentState(
            elapsedTime: 0,
            sessionState: "专注中",
            remainingTime: session.duration > 0 ? session.duration : nil
        )
        
        // 创建LiveActivity属性
        let attributes = FocusSessionAttributes(
            title: session.title,
            startTime: session.startTime,
            tags: session.tags
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            self.currentActivity = activity
            logger.debug("成功启动LiveActivity: \(activity.id)")
        } catch {
            logger.error("启动LiveActivity失败: \(error.localizedDescription)")
        }
    }
    
    // 更新现有的LiveActivity
    func updateLiveActivity(elapsedTime: TimeInterval, state: FocusSessionState, remainingTime: TimeInterval? = nil) async {
        guard let activity = currentActivity else {
            logger.debug("没有活动的LiveActivity可更新")
            return
        }
        
        let updatedState = FocusSessionAttributes.ContentState(
            elapsedTime: elapsedTime,
            sessionState: state.rawValue,
            remainingTime: remainingTime
        )
        
        await activity.update(.init(state: updatedState, staleDate: nil))
        logger.debug("已更新LiveActivity: \(activity.id), 状态: \(state.rawValue), 已过时间: \(elapsedTime)")
    }
    
    // 结束LiveActivity
    func endLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = FocusSessionAttributes.ContentState(
            elapsedTime: 0,
            sessionState: "已结束",
            remainingTime: nil
        )
        
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        self.currentActivity = nil
        logger.debug("已结束LiveActivity: \(activity.id)")
    }
    
    // 检查是否有正在进行的LiveActivity
    var hasActiveSession: Bool {
        return currentActivity != nil
    }
} 