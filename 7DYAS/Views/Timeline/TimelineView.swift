//
//  TimelineView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

// FlowLayout: 自定义布局，支持自动换行
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var frames: [CGRect] = []
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            
            if currentX + subviewSize.width > maxWidth && currentX > 0 {
                // 换行
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: subviewSize.width, height: subviewSize.height))
            
            currentX += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
        }
        
        bounds = CGSize(width: maxWidth, height: currentY + lineHeight)
    }
}

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
    @State private var isExpanded = false
    @State private var isAnimating = false
    
    private var relatedTask: Task? {
        guard let taskId = session.relatedTask else { return nil }
        return dataManager.tasks.first { $0.id == taskId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主要内容行
            Button(action: {
                // 模糊和展开同时进行
                withAnimation(.easeOut(duration: 0.3)) {
                    isExpanded.toggle()
                    isAnimating = true
                }
                
                // 在动画完成后清除模糊状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isAnimating = false
                    }
                }
            }) {
                if isExpanded {
                    // 展开状态：垂直布局，最大化利用空间
                    VStack(alignment: .leading, spacing: 12) {
                        // 第一行：时间信息 + 标题 + 用时
                        HStack(alignment: .center, spacing: 12) {
                            // 左侧：时间信息
                            VStack(spacing: 6) {
                                Text(session.formattedStartTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                
                                Text(session.formattedEndTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 50)
                            
                            // 中间：专注标题
                            VStack(alignment: .leading, spacing: 0) {
                                Text(session.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            // 右侧：用时
                            Text(session.formattedDuration)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        // 第二行：专注描述（如果有）
                        if !session.notes.isEmpty {
                            HStack(alignment: .top, spacing: 0) {
                                // 左侧占位（与时间信息对齐）
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 50)
                                
                                // 描述内容，延伸到右边界
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(session.notes)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                        .opacity(isAnimating ? 0.3 : 1.0)
                                        .animation(.easeOut(duration: 0.3), value: isAnimating)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // 第三行：事项和标签（延伸到右边界）
                        HStack {
                            // 左侧占位（与时间信息对齐）
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 50)
                            
                            // 事项和标签内容，延伸到右边界
                            VStack(alignment: .leading, spacing: 8) {
                                FlowLayout(spacing: 6) {
                                    // 关联事件
                                    ForEach(session.relatedEvents, id: \.self) { event in
                                        HStack(spacing: 4) {
                                            Text("@")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            Text(event)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    
                                    // 关联任务（如果有的话）
                                    if let task = relatedTask {
                                        HStack(spacing: 4) {
                                            Text("@")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.purple)
                                            Text(task.title)
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    
                                    // 标签
                                    ForEach(session.tags, id: \.self) { tag in
                                        HStack(spacing: 2) {
                                            Text("#")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            Text(tag)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                                .opacity(isAnimating ? 0.3 : 1.0)
                                .animation(.easeOut(duration: 0.3), value: isAnimating)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                } else {
                    // 收起状态：保持原有的水平布局
                    HStack(alignment: .center, spacing: 12) {
                        // 左侧：时间信息（开始时间 + 圆形分隔 + 结束时间）
                        VStack(spacing: 6) {
                            Text(session.formattedStartTime)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                            
                            Text(session.formattedEndTime)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 50)
                        
                        // 中间：专注标题
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            // 专注描述 - 默认显示，点击展开/收起
                            if !session.notes.isEmpty {
                                Text(session.notes)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            // 收起状态：智能显示（原有逻辑）
                            GeometryReader { geometry in
                                let availableWidth = geometry.size.width
                                let minWidthPerItem: CGFloat = 80 // 每个项目的最小宽度
                                
                                // 计算总项目数量
                                let totalEvents = session.relatedEvents.count + (relatedTask != nil ? 1 : 0)
                                let totalTags = session.tags.count
                                let totalItems = totalEvents + totalTags
                                
                                // 判断是否有足够空间显示所有内容
                                let shouldShowSummary = totalItems > 0 && (CGFloat(totalItems) * minWidthPerItem > availableWidth)
                                
                                HStack(spacing: 8) {
                                    if shouldShowSummary {
                                        // 显示数量统计
                                        if totalEvents > 0 {
                                            HStack(spacing: 4) {
                                                Text("@")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                Text("\(totalEvents)个事件")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        
                                        if totalTags > 0 {
                                            HStack(spacing: 4) {
                                                Text("#")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.blue)
                                                Text("\(totalTags)个标签")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    } else {
                                        // 显示具体内容
                                        // 关联事件
                                        ForEach(session.relatedEvents, id: \.self) { event in
                                            HStack(spacing: 4) {
                                                Text("@")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                                Text(event)
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        
                                        // 关联任务（如果有的话）
                                        if let task = relatedTask {
                                            HStack(spacing: 4) {
                                                Text("@")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.purple)
                                                Text(task.title)
                                                    .font(.caption)
                                                    .foregroundColor(.purple)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        
                                        // 标签
                                        ForEach(session.tags, id: \.self) { tag in
                                            HStack(spacing: 2) {
                                                Text("#")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.blue)
                                                Text(tag)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 24) // 固定高度以确保布局稳定
                        }
                        
                        Spacer()
                        
                        // 右侧：用时
                        Text(session.formattedDuration)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(16)
            .blur(radius: isAnimating ? 2 : 0)
            .animation(.easeOut(duration: 0.3), value: isAnimating)
        }
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
