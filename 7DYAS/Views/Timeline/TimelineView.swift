//
//  TimelineView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct TimelineView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var timerService: TimerService
    
    var body: some View {
        // 直接显示时间线内容，日期栏现在在 ContentView 中管理
        TimelineContent(selectedDate: selectedDate)
            .padding(.top, 100) // 为悬浮日期栏留出更多空间
    }
}

struct TimelineHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        return formatter
    }
    
    var body: some View {
        // 悬浮透明玻璃样式的日期栏
        HStack {
            // 日期选择按钮
            Button(action: { showingDatePicker = true }) {
                HStack(spacing: 8) {
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // 今日专注时间统计
            TodayFocusStats()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16) // 左右留边距
        .padding(.top, 8) // 顶部留边距
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2) // 添加阴影增强悬浮效果
    }
}

struct TodayFocusStats: View {
    @EnvironmentObject var timerService: TimerService
    
    private var totalFocusTime: TimeInterval {
        timerService.getTotalFocusTimeToday()
    }
    
    private var sessionCount: Int {
        timerService.getTodaysSessions().count
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("今日专注")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(formatTime(totalFocusTime))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("(\(sessionCount)次)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Rectangle()
                .fill(.orange.opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct TimelineContent: View {
    let selectedDate: Date
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var timerService: TimerService
    
    private var sessionsForDate: [FocusSession] {
        timerService.getSessionsForDate(selectedDate)
    }
    
    var body: some View {
        if sessionsForDate.isEmpty {
            EmptyTimelineView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sessionsForDate) { session in
                        FocusSessionCard(session: session)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    Text("暂无专注记录")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("开始一个专注时间来记录你的效率时光")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2 - 50 // 稍微往上偏移，考虑底部按钮
            )
        }
        .padding()
    }
}

struct FocusSessionCard: View {
    let session: FocusSession
    @EnvironmentObject var dataManager: DataManager
    
    private var relatedTask: Task? {
        guard let taskId = session.relatedTask else { return nil }
        return dataManager.tasks.first { $0.id == taskId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 时间信息
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(session.formattedStartTime) - \(session.formattedEndTime)")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text(session.formattedDuration)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 专注时长显示
                Text(session.formattedDuration)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            // 标签
            if !session.tags.isEmpty {
                HStack {
                    ForEach(session.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // 关联任务
            if let task = relatedTask {
                HStack {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("关联: \(task.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            // 备注
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("确定") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    TimelineView(selectedDate: .constant(Date()))
        .environmentObject(DataManager.shared)
        .environmentObject(TimerService())
}
