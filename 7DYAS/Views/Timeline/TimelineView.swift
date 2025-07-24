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
        // 直接显示时间线内容，内容可以在悬浮组件下方显示
        TimelineContent(selectedDate: selectedDate)
    }
}

struct TimelineHeader: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    var body: some View {
        // 悬浮透明玻璃样式的日期栏
        HStack {
            // 日期选择按钮
            Button(action: { showingDatePicker = true }) {
                VStack(spacing: 2) {
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(weekdayFormatter.string(from: selectedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        VStack(alignment: .center, spacing: 4) {
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
                .fill(Color(.systemOrange).opacity(0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if totalSeconds < 60 {
            return "\(seconds)秒"
        } else if hours > 0 {
            if minutes > 0 {
                return "\(hours)小时\(minutes)分钟"
            } else {
                return "\(hours)小时"
            }
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct TimelineContent: View {
    let selectedDate: Date
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var timerService: TimerService
    @State private var lastSessionCount = 0
    
    private var sessionsForDate: [FocusSession] {
        timerService.getSessionsForDate(selectedDate)
    }
    
    var body: some View {
        if sessionsForDate.isEmpty {
            GeometryReader { geometry in
                EmptyTimelineView()
                    .frame(minHeight: geometry.size.height) // 使用全屏高度
            }
        } else {
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    ScrollView {
                        // 增加顶部空间高度，将专注事项生成位置下移
                        Color.clear.frame(height: 160)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(Array(sessionsForDate.enumerated()), id: \.element.id) { index, session in
                                VStack(spacing: 0) {
                                    FocusSessionCard(session: session)
                                        .id(session.id) // 为每个卡片添加ID以支持滚动定位
                                    
                                    // 在每个专注事项下方添加渐变分隔线，除了最后一个
                                    if index < sessionsForDate.count - 1 {
                                        GradientDivider()
                                    }
                                }
                            }
                            
                            // 底部统计信息区域
                            TimelineBottomStats()
                                .id("bottom_spacer")
                        }
                        .padding(.bottom, 120) // 为底部悬浮按钮留出空间
                    }
                    .frame(minHeight: geometry.size.height) // 使用全屏高度
                }
                .onChange(of: dataManager.focusSessions) { oldSessions, newSessions in
                    // 当专注会话数据发生任何变化时，检查今天的数据
                    let todaySessions = timerService.getSessionsForDate(selectedDate)
                    if todaySessions.count > lastSessionCount {
                        lastSessionCount = todaySessions.count
                        // 只有当添加了新项目时，才滚动到底部
                        if let lastSession = todaySessions.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(lastSession.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .onChange(of: selectedDate) { oldDate, newDate in
                    // 当切换日期时，只更新计数，不自动滚动
                    lastSessionCount = sessionsForDate.count
                }
                .onAppear {
                    // 视图出现时只初始化计数，不自动滚动
                    lastSessionCount = sessionsForDate.count
                }
            }
        }
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 增加顶部空间高度，将内容位置下移
                Color.clear.frame(height: 160)
                
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
                .frame(maxWidth: .infinity)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 - 50 // 稍微上移，视觉上更平衡
                )
            }
            .padding(.bottom, 120) // 为底部悬浮按钮留出空间
        }
    }
}

struct FocusSessionCard: View {
    let session: FocusSession
    @EnvironmentObject var dataManager: DataManager
    @State private var isExpanded = false
    @State private var isAnimating = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    private var relatedTask: Task? {
        guard let taskId = session.relatedTask else { return nil }
        return dataManager.tasks.first { $0.id == taskId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主要内容行
            Button(action: {
                // 切换展开状态
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
                                        .background(Color(.systemGreen).opacity(0.15))
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
                                        .background(Color(.systemPurple).opacity(0.15))
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
                                        .background(Color(.systemBlue).opacity(0.15))
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
                                            .background(Color(.systemGreen).opacity(0.15))
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
                                            .background(Color(.systemBlue).opacity(0.15))
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
                                            .background(Color(.systemGreen).opacity(0.15))
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
                                            .background(Color(.systemPurple).opacity(0.15))
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
                                            .background(Color(.systemBlue).opacity(0.15))
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
            .padding(.horizontal, 20) // 左右内边距20pt
            .padding(.vertical, 16) // 上下内边距16pt
            .blur(radius: isAnimating ? 2 : 0)
            .animation(.easeOut(duration: 0.3), value: isAnimating)
        }
        .background(Color(.systemBackground)) // 使用系统背景色以适配深色模式
        .contentShape(Rectangle()) // 确保整个区域都可点击
        .contextMenu {
            // 编辑按钮
            Button(action: {
                showingEditSheet = true
            }) {
                Label("编辑", systemImage: "pencil")
            }
            
            // 删除按钮
            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("删除", systemImage: "trash")
            }
        } preview: {
            // 预览视图 - 显示专注记录的预览
            FocusSessionPreview(session: session)
        }
        .sheet(isPresented: $showingEditSheet) {
            FocusSessionEditSheet(session: session)
                .environmentObject(dataManager)
        }
        .alert("删除专注记录", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                dataManager.deleteFocusSession(session)
            }
        } message: {
            Text("确定要删除这条专注记录吗？此操作无法撤销。")
        }
    }
}

// 专注记录预览组件（用于上下文菜单）
struct FocusSessionPreview: View {
    let session: FocusSession
    @EnvironmentObject var dataManager: DataManager
    
    private var relatedTask: Task? {
        guard let taskId = session.relatedTask else { return nil }
        return dataManager.tasks.first { $0.id == taskId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和时间
            HStack(alignment: .center, spacing: 12) {
                // 时间信息
                VStack(spacing: 4) {
                    Text(session.formattedStartTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(session.formattedEndTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(width: 40)
                
                // 专注标题
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !session.notes.isEmpty {
                        Text(session.notes)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // 用时
                Text(session.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            // 标签和事件
            if !session.tags.isEmpty || !session.relatedEvents.isEmpty || relatedTask != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // 关联事件
                        ForEach(session.relatedEvents, id: \.self) { event in
                            HStack(spacing: 3) {
                                Text("@")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text(event)
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGreen).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // 关联任务
                        if let task = relatedTask {
                            HStack(spacing: 3) {
                                Text("@")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text(task.title)
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemPurple).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // 标签
                        ForEach(session.tags, id: \.self) { tag in
                            HStack(spacing: 2) {
                                Text("#")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text(tag)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemBlue).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 280) // 限制预览宽度
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

// 专注记录编辑Sheet
struct FocusSessionEditSheet: View {
    let session: FocusSession
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedTags: [String]
    @State private var editedEvents: [String]
    @State private var tagInput = ""
    @State private var eventInput = ""
    @State private var showingDeleteAlert = false
    
    init(session: FocusSession) {
        self.session = session
        self._editedTitle = State(initialValue: session.title)
        self._editedDescription = State(initialValue: session.notes)
        self._editedTags = State(initialValue: session.tags)
        self._editedEvents = State(initialValue: session.relatedEvents)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 时间信息（只读）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("专注时间")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("开始时间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(session.formattedStartTime)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("持续时长")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(session.formattedDuration)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 专注标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专注标题")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("专注标题", text: $editedTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // 专注描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专注描述")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("专注描述", text: $editedDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .font(.body)
                    }
                    
                    // 标签编辑
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签 #")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        EditableTagField(
                            input: $tagInput,
                            selectedTags: $editedTags,
                            placeholder: "添加标签，如 #工作 #学习"
                        )
                    }
                    
                    // 事件编辑
                    VStack(alignment: .leading, spacing: 8) {
                        Text("关联事件 @")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        EditableEventField(
                            input: $eventInput,
                            selectedEvents: $editedEvents,
                            placeholder: "关联事件，如 @会议 @项目"
                        )
                    }
                    
                    // 删除按钮
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.subheadline)
                            Text("删除此专注记录")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("编辑专注记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("删除专注记录", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    dataManager.deleteFocusSession(session)
                    dismiss()
                }
            } message: {
                Text("确定要删除这条专注记录吗？此操作无法撤销。")
            }
        }
    }
    
    private func saveChanges() {
        // 创建更新后的专注记录
        let updatedSession = FocusSession(
            id: session.id,
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: session.startTime,
            duration: session.duration,
            tags: editedTags,
            relatedEvents: editedEvents,
            notes: editedDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            relatedTask: session.relatedTask
        )
        
        // 更新数据
        dataManager.updateFocusSession(updatedSession)
        
        // 关闭弹窗
        dismiss()
    }
}

// 可编辑标签输入组件
struct EditableTagField: View {
    @Binding var input: String
    @Binding var selectedTags: [String]
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholder, text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("添加", action: addTag)
                    .buttonStyle(.bordered)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 已选择的标签
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBlue).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private func addTag() {
        let tag = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        if !tag.isEmpty && !selectedTags.contains(tag) {
            selectedTags.append(tag)
            input = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
}

// 可编辑事件输入组件
struct EditableEventField: View {
    @Binding var input: String
    @Binding var selectedEvents: [String]
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholder, text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addEvent()
                    }
                
                Button("添加", action: addEvent)
                    .buttonStyle(.bordered)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 已选择的事件
            if !selectedEvents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedEvents, id: \.self) { event in
                            HStack(spacing: 4) {
                                Text("@\(event)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Button(action: { removeEvent(event) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGreen).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private func addEvent() {
        let event = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        
        if !event.isEmpty && !selectedEvents.contains(event) {
            selectedEvents.append(event)
            input = ""
        }
    }
    
    private func removeEvent(_ event: String) {
        selectedEvents.removeAll { $0 == event }
    }
}

// 时间线底部统计信息组件
struct TimelineBottomStats: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var totalFocusTime: TimeInterval {
        dataManager.getTotalFocusTime()
    }
    
    private var formattedTotalTime: String {
        let totalSeconds = Int(totalFocusTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "至今共专注\(hours)时\(minutes)分\(seconds)秒"
        } else if minutes > 0 {
            return "至今共专注\(minutes)分\(seconds)秒"
        } else {
            return "至今共专注\(seconds)秒"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 统计信息
            VStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(formattedTotalTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20) // 与卡片内容对齐
            
            // 底部留白
            Color.clear
                .frame(height: 60)
        }
        .frame(minHeight: 180) // 增加底部区域高度
        .padding(.top, 30) // 与最后一个专注卡片保持距离
    }
}

// 自定义渐变分隔线组件
struct GradientDivider: View {
    var body: some View {
        // 全屏宽度的渐变分隔线
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color.gray.opacity(0.15), location: 0.2),
                        .init(color: Color.gray.opacity(0.15), location: 0.8),
                        .init(color: Color.clear, location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
            .frame(maxWidth: .infinity) // 使用全屏宽度
    }
}

#Preview {
    TimelineView(selectedDate: .constant(Date()))
        .environmentObject(DataManager.shared)
        .environmentObject(TimerService())
}
