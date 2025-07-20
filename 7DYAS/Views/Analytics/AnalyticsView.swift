//
//  AnalyticsView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var timerService: TimerService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 简化的顶部导航
                AnalyticsHeader()
                
                // 今日概览
                TodayOverviewSection()
                
                // 专注时间统计
                FocusTimeSection()
                
                // 任务完成统计
                TaskCompletionSection()
                
                // 打卡统计
                CheckInStatsSection()
                
                // 占位区域
                PlaceholderSection()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // 为悬浮按钮留出空间
        }
    }
}

struct AnalyticsHeader: View {
    var body: some View {
        HStack {
            Text("查看你的效率统计")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct TodayOverviewSection: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var timerService: TimerService
    
    private var todayTasks: [Task] {
        dataManager.getTasksForDate(Date())
    }
    
    private var completedTasks: Int {
        todayTasks.filter { $0.isCompleted }.count
    }
    
    private var totalFocusTime: TimeInterval {
        timerService.getTotalFocusTimeToday()
    }
    
    private var checkedInToday: Int {
        dataManager.getActiveCheckIns().filter { $0.hasCheckedInToday }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日概览")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "完成任务",
                    value: "\(completedTasks)",
                    subtitle: "共\(todayTasks.count)个",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "专注时间",
                    value: formatTime(totalFocusTime),
                    subtitle: "\(timerService.getTodaysSessions().count)次",
                    color: .orange,
                    icon: "timer"
                )
                
                StatCard(
                    title: "打卡完成",
                    value: "\(checkedInToday)",
                    subtitle: "共\(dataManager.getActiveCheckIns().count)个",
                    color: .blue,
                    icon: "checkmark.square.fill"
                )
                
                StatCard(
                    title: "新增想法",
                    value: "\(getTodayIdeasCount())",
                    subtitle: "灵感记录",
                    color: .purple,
                    icon: "lightbulb.fill"
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getTodayIdeasCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.temporaryIdeas.filter { idea in
            idea.createdDate >= today && idea.createdDate < tomorrow
        }.count
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FocusTimeSection: View {
    @EnvironmentObject var timerService: TimerService
    
    private var weeklyFocusTime: [(String, TimeInterval)] {
        let calendar = Calendar.current
        let today = Date()
        var weekData: [(String, TimeInterval)] = []
        
        for i in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let sessions = timerService.getSessionsForDate(date)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayName = formatter.string(from: date)
            
            weekData.append((dayName, totalTime))
        }
        
        return weekData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本周专注时间")
                .font(.headline)
                .fontWeight(.semibold)
            
            // 简化的图表显示
            VStack(spacing: 8) {
                ForEach(0..<weeklyFocusTime.count, id: \.self) { index in
                    let (day, time) = weeklyFocusTime[index]
                    let maxTime = weeklyFocusTime.map { $0.1 }.max() ?? 1
                    let progress = maxTime > 0 ? time / maxTime : 0
                    
                    HStack {
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 30, alignment: .leading)
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2)
                        
                        Text(formatMinutes(time))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatMinutes(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        return "\(minutes)m"
    }
}

struct TaskCompletionSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var completionStats: (completed: Int, total: Int, rate: Double) {
        let total = dataManager.tasks.count
        let completed = dataManager.tasks.filter { $0.isCompleted }.count
        let rate = total > 0 ? Double(completed) / Double(total) : 0
        
        return (completed, total, rate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("任务完成情况")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // 完成率圆环（简化显示）
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: completionStats.rate)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f%%", completionStats.rate * 100))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Text("完成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("已完成: \(completionStats.completed)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                        
                        Text("未完成: \(completionStats.total - completionStats.completed)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text("总计: \(completionStats.total)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CheckInStatsSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var activeCheckIns: [CheckIn] {
        dataManager.getActiveCheckIns()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("打卡统计")
                .font(.headline)
                .fontWeight(.semibold)
            
            if activeCheckIns.isEmpty {
                Text("暂无打卡项目")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeCheckIns.prefix(3)) { checkIn in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: checkIn.category.icon)
                                    .font(.caption)
                                    .foregroundColor(checkIn.category.color)
                                
                                Text(checkIn.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(checkIn.currentStreak)天")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(checkIn.category.color)
                                
                                Text("连续")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if activeCheckIns.count > 3 {
                        Text("还有\(activeCheckIns.count - 3)个打卡项目...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlaceholderSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("更多统计功能")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("我们正在开发更多有用的数据分析功能")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(DataManager.shared)
        .environmentObject(TimerService())
}
