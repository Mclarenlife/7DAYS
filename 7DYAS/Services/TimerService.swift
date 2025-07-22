//
//  TimerService.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import Combine

class TimerService: ObservableObject {
    @Published var currentSession: FocusSession?
    @Published var sessionState: FocusSessionState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    
    private let dataManager = DataManager.shared
    
    // MARK: - Timer Control
    func startSession(title: String, tags: [String] = [], relatedTask: UUID? = nil) {
        guard sessionState == .idle else { return }
        
        // 检查是否启用了自定义开始时间
        let sessionStartTime: Date
        var initialElapsedTime: TimeInterval = 0
        
        if UserDefaults.standard.bool(forKey: "enableCustomStartTime"),
           let customStartTime = UserDefaults.standard.object(forKey: "customTimerStartTime") as? Date {
            // 使用今天的日期 + 自定义的时间
            let calendar = Calendar.current
            let today = Date()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: customStartTime)
            sessionStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                                           minute: timeComponents.minute ?? 0, 
                                           second: 0, 
                                           of: today) ?? Date()
            
            // 如果设置时间在当前时间之前，计算已经过去的时间
            let currentTime = Date()
            if sessionStartTime < currentTime {
                initialElapsedTime = currentTime.timeIntervalSince(sessionStartTime)
            }
            
            // 使用后重置自定义开始时间设置，避免下次意外使用
            UserDefaults.standard.set(false, forKey: "enableCustomStartTime")
        } else {
            sessionStartTime = Date()
        }
        
        currentSession = FocusSession(
            title: title,
            startTime: sessionStartTime,
            tags: tags,
            relatedTask: relatedTask
        )
        
        sessionState = .running
        isRunning = true
        startTime = Date() // 实际计时开始时间仍使用当前时间
        elapsedTime = initialElapsedTime // 设置初始已过时间
        pausedTime = 0
        
        startTimer()
    }
    
    func pauseSession() {
        guard sessionState == .running else { return }
        
        sessionState = .paused
        isRunning = false
        stopTimer()
        
        if let start = startTime {
            pausedTime += Date().timeIntervalSince(start)
        }
    }
    
    func resumeSession() {
        guard sessionState == .paused else { return }
        
        sessionState = .running
        isRunning = true
        startTime = Date()
        
        startTimer()
    }
    
    func stopSession(notes: String = "") {
        guard sessionState == .running || sessionState == .paused else { return }
        
        sessionState = .completed
        isRunning = false
        stopTimer()
        
        // 计算总时长
        let finalDuration: TimeInterval
        if sessionState == .running, let start = startTime {
            finalDuration = pausedTime + Date().timeIntervalSince(start)
        } else {
            finalDuration = pausedTime
        }
        
        // 更新会话信息
        if var session = currentSession {
            session.duration = finalDuration
            session.endTime = session.startTime.addingTimeInterval(finalDuration)
            session.notes = notes
            
            // 保存到数据管理器
            dataManager.addFocusSession(session)
        }
        
        // 重置状态
        resetSession()
    }
    
    func cancelSession() {
        sessionState = .idle
        isRunning = false
        stopTimer()
        resetSession()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard let start = startTime, let session = currentSession else { return }
        
        let currentTime = Date()
        
        // 如果设定的开始时间在未来，显示0
        if session.startTime > currentTime {
            elapsedTime = 0
            return
        }
        
        // 如果设定的开始时间在过去，从设定时间开始计算
        if session.startTime < start {
            // 计算从设定开始时间到现在的总时间
            let totalTimeFromCustomStart = currentTime.timeIntervalSince(session.startTime)
            
            // 如果当前是运行状态
            if sessionState == .running {
                // 计算实际运行时间（排除暂停时间）
                let actualRunningTime = currentTime.timeIntervalSince(start)
                elapsedTime = totalTimeFromCustomStart - (pausedTime > 0 ? (totalTimeFromCustomStart - actualRunningTime - pausedTime) : 0)
            }
        } else {
            // 正常情况：从实际开始时间计算
            elapsedTime = pausedTime + currentTime.timeIntervalSince(start)
        }
        
        // 确保时间不为负数
        elapsedTime = max(0, elapsedTime)
    }
    
    private func resetSession() {
        currentSession = nil
        elapsedTime = 0
        startTime = nil
        pausedTime = 0
    }
    
    // MARK: - Formatting Helpers
    func formattedElapsedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Session History
    func getTodaysSessions() -> [FocusSession] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.focusSessions.filter { session in
            session.startTime >= today && session.startTime < tomorrow
        }
    }
    
    func getTotalFocusTimeToday() -> TimeInterval {
        return getTodaysSessions().reduce(0) { $0 + $1.duration }
    }
    
    func getSessionsForDate(_ date: Date) -> [FocusSession] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return dataManager.focusSessions.filter { session in
            session.startTime >= startOfDay && session.startTime < endOfDay
        }.sorted { $0.startTime < $1.startTime } // 按开始时间正序排列，早的在前
    }
    
    // MARK: - Time Helpers
    func isStartTimeInFuture() -> Bool {
        guard let session = currentSession else { return false }
        return session.startTime > Date()
    }
    
    // MARK: - Dynamic Start Time Update
    func updateSessionStartTime() {
        guard var session = currentSession else { return }
        guard sessionState == .running || sessionState == .paused else { return }
        
        // 检查是否启用了自定义开始时间
        if UserDefaults.standard.bool(forKey: "enableCustomStartTime"),
           let customStartTime = UserDefaults.standard.object(forKey: "customTimerStartTime") as? Date {
            
            // 计算新的开始时间
            let calendar = Calendar.current
            let today = Date()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: customStartTime)
            let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                           minute: timeComponents.minute ?? 0,
                                           second: 0,
                                           of: today) ?? Date()
            
            // 更新会话的开始时间
            session.startTime = newStartTime
            currentSession = session
            
            // 重新计算已过时间
            recalculateElapsedTime()
        }
    }
    
    private func recalculateElapsedTime() {
        guard let session = currentSession, let start = startTime else { return }
        
        let currentTime = Date()
        
        // 如果设定的开始时间在未来，重置为0
        if session.startTime > currentTime {
            elapsedTime = 0
            return
        }
        
        // 重新计算从设定开始时间到现在的总时间
        if session.startTime < start {
            // 计算从设定开始时间到现在的总时间，减去暂停的时间
            let totalTimeFromCustomStart = currentTime.timeIntervalSince(session.startTime)
            
            // 如果当前是运行状态，使用从自定义开始时间的总时间
            if sessionState == .running {
                elapsedTime = totalTimeFromCustomStart - (pausedTime > 0 ? pausedTime : 0)
            } else if sessionState == .paused {
                // 如果是暂停状态，需要加上之前累积的暂停时间
                elapsedTime = pausedTime
            }
        } else {
            // 正常情况：从实际开始时间计算
            if sessionState == .running {
                elapsedTime = pausedTime + currentTime.timeIntervalSince(start)
            }
        }
        
        // 确保时间不为负数
        elapsedTime = max(0, elapsedTime)
    }
}
