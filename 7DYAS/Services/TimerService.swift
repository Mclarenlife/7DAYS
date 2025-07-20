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
        
        currentSession = FocusSession(
            title: title,
            startTime: Date(),
            tags: tags,
            relatedTask: relatedTask
        )
        
        sessionState = .running
        isRunning = true
        startTime = Date()
        elapsedTime = 0
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
        guard let start = startTime else { return }
        elapsedTime = pausedTime + Date().timeIntervalSince(start)
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
        }
    }
}
