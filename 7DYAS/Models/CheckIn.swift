//
//  CheckIn.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import Foundation
import SwiftUI

struct CheckIn: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var targetDays: Int // 目标天数
    var currentStreak: Int // 当前连续天数
    var totalDays: Int // 总完成天数
    var checkInDates: [Date] // 打卡日期记录
    var createdDate: Date
    var isActive: Bool
    var category: CheckInCategory
    var reminderTime: Date? // 提醒时间
    
    enum CheckInCategory: String, CaseIterable, Codable {
        case health = "健康"
        case study = "学习"
        case work = "工作"
        case hobby = "兴趣"
        case habit = "习惯"
        case exercise = "运动"
        
        var icon: String {
            switch self {
            case .health:
                return "heart.fill"
            case .study:
                return "book.fill"
            case .work:
                return "briefcase.fill"
            case .hobby:
                return "star.fill"
            case .habit:
                return "checkmark.circle.fill"
            case .exercise:
                return "figure.run"
            }
        }
        
        var color: Color {
            switch self {
            case .health:
                return .red
            case .study:
                return .blue
            case .work:
                return .purple
            case .hobby:
                return .orange
            case .habit:
                return .green
            case .exercise:
                return .cyan
            }
        }
    }
    
    var completionRate: Double {
        guard targetDays > 0 else { return 0 }
        return Double(totalDays) / Double(targetDays)
    }
    
    var hasCheckedInToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return checkInDates.contains { Calendar.current.isDate($0, inSameDayAs: today) }
    }
    
    init(title: String, description: String = "", targetDays: Int = 30, category: CheckInCategory = .habit, reminderTime: Date? = nil) {
        self.title = title
        self.description = description
        self.targetDays = targetDays
        self.currentStreak = 0
        self.totalDays = 0
        self.checkInDates = []
        self.createdDate = Date()
        self.isActive = true
        self.category = category
        self.reminderTime = reminderTime
    }
    
    mutating func checkIn() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 如果今天已经打卡，则不重复打卡
        guard !hasCheckedInToday else { return }
        
        checkInDates.append(today)
        totalDays += 1
        
        // 更新连续天数
        if let lastCheckIn = checkInDates.dropLast().last {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(lastCheckIn, inSameDayAs: yesterday) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
    }
    
    mutating func uncheckIn() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = checkInDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            checkInDates.remove(at: index)
            totalDays = max(0, totalDays - 1)
            
            // 重新计算连续天数
            updateStreak()
        }
    }
    
    private mutating func updateStreak() {
        guard !checkInDates.isEmpty else {
            currentStreak = 0
            return
        }
        
        let sortedDates = checkInDates.sorted(by: >)
        let today = Calendar.current.startOfDay(for: Date())
        
        currentStreak = 0
        var checkDate = today
        
        for date in sortedDates {
            if Calendar.current.isDate(date, inSameDayAs: checkDate) {
                currentStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!) {
                currentStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
    }
}
