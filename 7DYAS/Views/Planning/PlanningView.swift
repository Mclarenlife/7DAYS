//
//  PlanningView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI
import Combine

struct PlanningView: View {
    @Binding var selectedDate: Date
    @Binding var selectedViewType: PlanningViewType
    @Binding var selectedDaySubView: ContentView.DaySubViewType
    @StateObject private var viewModel = PlanningViewModel()
    @State private var showingNewTask = false
    @State private var showCompleted = false
    
    enum PlanningViewType: String, CaseIterable {
        case day = "日"
        case week = "周"
        case month = "月"
        case year = "年"
        
        var icon: String {
            switch self {
            case .day: return "calendar.day.timeline.left"
            case .week: return "calendar"
            case .month: return "calendar.badge.plus"
            case .year: return "calendar.badge.clock"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedViewType {
                case .day:
                    DayPlanningView(selectedDate: selectedDate, selectedSubView: selectedDaySubView)
                        .environmentObject(viewModel)
                case .week:
                    WeekPlanningView(selectedDate: selectedDate)
                        .environmentObject(viewModel)
                case .month:
                    MonthPlanningView(selectedDate: selectedDate)
                        .environmentObject(viewModel)
                case .year:
                    YearPlanningView(selectedDate: selectedDate)
                        .environmentObject(viewModel)
                }
            }
            // 悬浮添加按钮水平居中
            HStack {
                Spacer()
                FloatingAddButton {
                    showingNewTask = true
                }
                Spacer()
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showingNewTask) {
            NewTaskView()
                .environmentObject(viewModel)
        }
    }
}

struct PlanningHeader: View {
    @Binding var selectedViewType: PlanningView.PlanningViewType
    @Binding var selectedDate: Date
    let onNewTask: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch selectedViewType {
        case .day:
            formatter.dateFormat = "MM月dd日 EEEE"
        case .week:
            formatter.dateFormat = "MM月dd日周"
        case .month:
            formatter.dateFormat = "yyyy年MM月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // 日期显示
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: onNewTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // 视图类型选择器
            HStack(spacing: 0) {
                ForEach(PlanningView.PlanningViewType.allCases, id: \.self) { type in
                    Button(action: { selectedViewType = type }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedViewType == type ? .white : .primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedViewType == type ? Color.blue : Color.clear
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // 日期导航
            DateNavigationView(selectedDate: $selectedDate, viewType: selectedViewType)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

struct DateNavigationView: View {
    @Binding var selectedDate: Date
    let viewType: PlanningView.PlanningViewType
    
    var body: some View {
        HStack {
            Button(action: previousPeriod) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: { selectedDate = Date() }) {
                Text("今天")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: nextPeriod) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func previousPeriod() {
        switch viewType {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        case .year:
            selectedDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextPeriod() {
        switch viewType {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        case .year:
            selectedDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// 删除原有的DayPlanningView定义，避免重复声明

struct TaskCard: View {
    let task: Task
    @EnvironmentObject var dataManager: DataManager
    @State private var showingTaskDetail = false
    
    var body: some View {
        Button(action: { showingTaskDetail = true }) {
            HStack(spacing: 12) {
                // 完成状态按钮
                Button(action: { dataManager.toggleTaskCompletion(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                        
                        Spacer()
                        
                        // 优先级指示器
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 8, height: 8)
                    }
                    
                    if !task.content.isEmpty {
                        Text(task.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if !task.tags.isEmpty {
                        HStack {
                            ForEach(task.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            
                            if task.tags.count > 3 {
                                Text("+\(task.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
        }
    }
}

// 周视图 - 简化实现
struct WeekPlanningView: View {
    let selectedDate: Date
    
    var body: some View {
        Text("周视图")
            .font(.title)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 月视图 - 简化实现
struct MonthPlanningView: View {
    let selectedDate: Date
    
    var body: some View {
        Text("月视图")
            .font(.title)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 年视图 - 简化实现
struct YearPlanningView: View {
    let selectedDate: Date
    
    var body: some View {
        Text("年视图")
            .font(.title)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlanningView(
        selectedDate: .constant(Date()),
        selectedViewType: .constant(.day),
        selectedDaySubView: .constant(.planning)
    )
    .environmentObject(DataManager.shared)
}
