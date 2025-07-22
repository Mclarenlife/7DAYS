//
//  ContentView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var timerService = TimerService()
    @State private var selectedTab: MainTab = .timeline
    @State private var showingNewIdea = false
    @State private var showingFocusTimer = false
    @State private var showingGlobalSearch = false
    @State private var showingBottomTimerBar = false // 底部计时条状态
    
    // 时间线日期栏状态
    @State private var timelineSelectedDate = Date()
    @State private var showingTimelineDatePicker = false
    
    // 计划视图状态
    @State private var planningSelectedDate = Date()
    @State private var showingPlanningDatePicker = false
    @State private var planningViewType: PlanningView.PlanningViewType = .day
    @State private var isExpandedDayView = true // 日视图展开状态 - 默认展开
    @State private var selectedDaySubView: DaySubViewType = .planning // 日视图子功能选择
    
    enum MainTab: Int, CaseIterable {
        case timeline = 0
        case planning = 1
        case checkin = 2
        case analytics = 3
        case temporary = 4
        
        var title: String {
            switch self {
            case .timeline: return "时间线"
            case .planning: return "计划"
            case .checkin: return "打卡"
            case .analytics: return "数据"
            case .temporary: return "暂存"
            }
        }
        
        var icon: String {
            switch self {
            case .timeline: return "clock"
            case .planning: return "calendar"
            case .checkin: return "checkmark.circle"
            case .analytics: return "chart.bar"
            case .temporary: return "tray"
            }
        }
    }
    
    enum DaySubViewType: String, CaseIterable {
        case planning = "计划"
        case dailyRoutine = "每日循环"
        case journal = "日志"
        
        var icon: String {
            switch self {
            case .planning: return "list.clipboard"
            case .dailyRoutine: return "arrow.triangle.2.circlepath"
            case .journal: return "book.pages"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 主内容区域 - 全屏显示
            ScrollViewReader { proxy in
                TabView(selection: $selectedTab) {
                    TimelineView(
                        selectedDate: $timelineSelectedDate
                    )
                    .tag(MainTab.timeline)
                    
                    PlanningView(
                        selectedDate: $planningSelectedDate,
                        selectedViewType: $planningViewType,
                        selectedDaySubView: $selectedDaySubView
                    )
                        .tag(MainTab.planning)
                    
                    CheckInView()
                        .tag(MainTab.checkin)
                    
                    AnalyticsView()
                        .tag(MainTab.analytics)
                    
                    TemporaryView()
                        .tag(MainTab.temporary)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            
            // 悬浮顶部标签栏
            VStack {
                TopTabBar(selectedTab: $selectedTab, isFloating: true)
                
                Spacer()
            }
            .ignoresSafeArea(.all, edges: .top) // 忽略所有顶部安全区域
            
            // 时间线视图的悬浮日期栏 - 使用模糊动画组件
            VStack {
                Spacer()
                    .frame(height: 160) // 减少距离，让日期栏上移
                
                BlurAnimationWrapper(isVisible: selectedTab == .timeline) {
                    TimelineFloatingDateBar(
                        selectedDate: $timelineSelectedDate,
                        showingDatePicker: $showingTimelineDatePicker
                    )
                }
                
                Spacer()
            }
            
            // 计划视图的悬浮日期栏 - 使用相同的模糊动画效果
            VStack {
                Spacer()
                    .frame(height: 160) // 减少距离，让日期栏上移
                
                BlurAnimationWrapper(isVisible: selectedTab == .planning) {
                    PlanningFloatingDateBar(
                        selectedDate: $planningSelectedDate,
                        selectedViewType: $planningViewType,
                        showingDatePicker: $showingPlanningDatePicker,
                        isExpanded: $isExpandedDayView,
                        selectedSubView: $selectedDaySubView
                    )
                }
                
                Spacer()
            }
            
            // 底部悬浮操作栏
            VStack {
                Spacer()
                
                // 底部计时条
                if showingBottomTimerBar {
                    BottomTimerBar(
                        onTap: { 
                            showingFocusTimer = true 
                            showingBottomTimerBar = false
                        },
                        onDismiss: { showingBottomTimerBar = false }
                    )
                    .environmentObject(timerService)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 30) // 与FloatingActionBar保持一致的底部边距
                }
                
                FloatingActionBar(
                    onHomeAction: { selectedTab = .timeline },
                    onIdeaAction: { showingNewIdea = true },
                    onFocusAction: { showingFocusTimer = true },
                    onSearchAction: { showingGlobalSearch = true }
                )
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .environmentObject(dataManager)
        .environmentObject(timerService)
        .sheet(isPresented: $showingNewIdea) {
            NewIdeaView()
        }
        .overlay(
            // 底部专注弹窗
            BottomFocusSheet(
                isPresented: $showingFocusTimer,
                showingBottomTimerBar: $showingBottomTimerBar
            )
                .environmentObject(dataManager)
                .environmentObject(timerService)
        )
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView()
        }
        .sheet(isPresented: $showingTimelineDatePicker) {
            TimelineDatePickerSheet(selectedDate: $timelineSelectedDate)
        }
        .sheet(isPresented: $showingPlanningDatePicker) {
            PlanningDatePickerSheet(selectedDate: $planningSelectedDate)
        }
        .onChange(of: timerService.sessionState) { oldValue, newValue in
            // 当计时器状态变为空闲时，隐藏底部计时条
            if newValue == .idle {
                showingBottomTimerBar = false
            }
        }
    }
}

// 顶部标签栏组件
struct TopTabBar: View {
    @Binding var selectedTab: ContentView.MainTab
    @EnvironmentObject var dataManager: DataManager
    let isFloating: Bool
    
    @State private var currentStatIndex = 0
    @State private var timer: Timer?
    
    var statisticsTexts: [String] {
        let focusCount = dataManager.getTodayFocusSessionsCount()
        let tasksCount = dataManager.getTodayTasksCount()
        let checkInsCount = dataManager.getTodayCheckInsCount()
        
        return [
            "今日专注\(focusCount)次",
            "\(tasksCount)项待做",
            "\(checkInsCount)项待打卡"
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 应用标题 - 动态统计信息
            ZStack {
                // 居中的统计信息文字
                Text(statisticsTexts[currentStatIndex])
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    .id("stat-\(currentStatIndex)") // 强制重新渲染以触发过渡动画
                    .offset(y: 12) // 使用 offset 来下移文字，而不是用 Spacer
                
                // 右侧设置按钮
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: 12) // 与统计信息文字保持相同的垂直偏移
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50) // 恢复顶部padding，为状态栏和内容留出空间
            .padding(.bottom, 20) // 减少底部padding，缩小与标签栏的间距
            .onAppear {
                startStatisticsRotation()
            }
            .onDisappear {
                stopStatisticsRotation()
            }
            
            // 标签栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(ContentView.MainTab.allCases, id: \.self) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12) // 增加标签栏底部padding
            }
        }
        .background {
            // 使用 background 闭包语法来支持复杂的背景视图
            ZStack {
                // 渐变透明背景 - 从上到下逐渐透明，延伸到状态栏
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(.systemBackground).opacity(0.98), location: 0.0),
                        .init(color: Color(.systemBackground).opacity(0.7), location: 0.4),
                        .init(color: Color(.systemBackground).opacity(0.3), location: 0.8),
                        .init(color: Color(.systemBackground).opacity(0.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom,
                
                )
                
                // 模糊材质层
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            }
            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16)))
            .ignoresSafeArea(.all, edges: .top) // 确保背景延伸到状态栏
        }
        // .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4) // 阴影已移除
    }
    
    // MARK: - Statistics Rotation Methods
    private func startStatisticsRotation() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentStatIndex = (currentStatIndex + 1) % statisticsTexts.count
            }
        }
    }
    
    private func stopStatisticsRotation() {
        timer?.invalidate()
        timer = nil
    }
}

// 单个标签按钮
struct TabButton: View {
    let tab: ContentView.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tab.title)
                .font(.title)
                .fontWeight(.light)
                .foregroundColor(isSelected ? .blue : .primary)
                .frame(minWidth: 70)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 悬浮操作栏
struct FloatingActionBar: View {
    let onHomeAction: () -> Void
    let onIdeaAction: () -> Void
    let onFocusAction: () -> Void
    let onSearchAction: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 首页按钮
            Button(action: onHomeAction) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            // 中间操作按钮组
            HStack(spacing: 0) {
                // 想法按钮
                Button(action: onIdeaAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                        Text("想法")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 分割线
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // 专注按钮  
                Button(action: onFocusAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 16))
                        Text("专注")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 140, height: 50)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // 搜索按钮
            Button(action: onSearchAction) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 30)
    }
}

// 模糊动画包装组件
struct BlurAnimationWrapper<Content: View>: View {
    let content: Content
    let isVisible: Bool
    
    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.content = content()
    }
    
    var body: some View {
        content
            .blur(radius: isVisible ? 0 : 12) // 更强的模糊效果
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9) // 轻微缩放
            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isVisible) // 使用弹簧动画
    }
}

// 简化的动画背景组件
struct SimpleAnimatedBackground: View {
    let isFloating: Bool
    
    var body: some View {
        Group {
            if isFloating {
                Rectangle()
                    .fill(.ultraThinMaterial)
            } else {
                Color(.systemBackground)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isFloating) // 缩短动画时长，使用更简单的缓动
    }
}

// 使用 UIKit 实现的动画背景组件
struct NativeAnimatedBackground: UIViewRepresentable {
    let isFloating: Bool
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // 基础背景
        let baseBackgroundView = UIView()
        baseBackgroundView.backgroundColor = UIColor.systemBackground
        baseBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(baseBackgroundView)
        
        // 磨砂玻璃背景
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = isFloating ? 1.0 : 0.0
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            baseBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            baseBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            baseBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            baseBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 存储 blurView 引用
        containerView.tag = 999
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let blurView = uiView.subviews.compactMap({ $0 as? UIVisualEffectView }).first else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            blurView.alpha = self.isFloating ? 1.0 : 0.0
        })
    }
}

// 动画背景组件
struct AnimatedBackground: View {
    let isFloating: Bool
    @State private var animationProgress: Double = 0
    
    var body: some View {
        ZStack {
            // 基础背景
            Color(.systemBackground)
            
            // 磨砂玻璃覆盖层
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(animationProgress)
        }
        .onAppear {
            animationProgress = isFloating ? 1 : 0
        }
        .onChange(of: isFloating) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationProgress = newValue ? 1 : 0
            }
        }
    }
}

// 计划视图悬浮日期栏组件
struct PlanningFloatingDateBar: View {
    @Binding var selectedDate: Date
    @Binding var selectedViewType: PlanningView.PlanningViewType
    @Binding var showingDatePicker: Bool
    @Binding var isExpanded: Bool
    @Binding var selectedSubView: ContentView.DaySubViewType
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch selectedViewType {
        case .day:
            formatter.dateFormat = "MM月dd日 EEEE"
        case .week:
            formatter.dateFormat = "MM月第W周"
        case .month:
            formatter.dateFormat = "yyyy年MM月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主日期栏
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
                
                // 视图类型选择器 - 改为下拉菜单
                Menu {
                    ForEach(PlanningView.PlanningViewType.allCases, id: \.self) { type in
                        Button(action: { 
                            selectedViewType = type
                        }) {
                            HStack {
                                Text(type.rawValue)
                                if selectedViewType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedViewType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Rectangle()
                            .fill(.blue.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // 展开的子功能栏
            if isExpanded && selectedViewType == .day {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(ContentView.DaySubViewType.allCases, id: \.self) { subView in
                            Button(action: { selectedSubView = subView }) {
                                Text(subView.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(selectedSubView == subView ? .blue : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Rectangle()
                                            .fill(selectedSubView == subView ? .blue.opacity(0.1) : .clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 30) // 左右留边距
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2) // 添加阴影增强悬浮效果
        .onChange(of: selectedViewType) { oldValue, newValue in
            // 监听视图类型变化，自动展开/收起
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = (newValue == .day)
            }
        }
    }
}

// 计划视图日期选择器 Sheet
struct PlanningDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 时间线悬浮日期栏组件
struct TimelineFloatingDateBar: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @EnvironmentObject var timerService: TimerService
    
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
        HStack {
            // 日期选择按钮
            Button(action: { showingDatePicker = true }) {
                VStack(spacing: 1) {
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(weekdayFormatter.string(from: selectedDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 今日专注时间统计
            TimelineFloatingFocusStats()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 30) // 左右留边距
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2) // 添加阴影增强悬浮效果
    }
}

// 悬浮日期栏中的专注统计组件
struct TimelineFloatingFocusStats: View {
    @EnvironmentObject var timerService: TimerService
    
    private var totalFocusTime: TimeInterval {
        timerService.getTotalFocusTimeToday()
    }
    
    private var sessionCount: Int {
        timerService.getTodaysSessions().count
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("专注\(sessionCount)次")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(formatTime(totalFocusTime))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Rectangle()
                .fill(.orange.opacity(0.15))
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

// 时间线日期选择器 Sheet
struct TimelineDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 底部专注弹窗组件
struct BottomFocusSheet: View {
    @Binding var isPresented: Bool
    @Binding var showingBottomTimerBar: Bool
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var dataManager: DataManager
    
    @State private var sessionTitle = ""
    @State private var sessionDescription = ""
    @State private var selectedTags: [String] = []
    @State private var relatedEvents: [String] = []
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimatingOut = false // 新增：控制模糊消失动画
    
    private let minHeight: CGFloat = 500
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.95
    
    var body: some View {
        ZStack {
            if isPresented {
                // 背景遮罩
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                
                // 弹窗内容
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // 拖拽指示器 - 电纸书风格
                        VStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 40, height: 2)
                        }
                        .frame(height: 40) // 设置拖拽区域高度
                        .frame(maxWidth: .infinity) // 横向填满以便拖拽
                        .background(Color(.systemGray6)) // 电纸书风格的浅灰背景
                        .contentShape(Rectangle()) // 确保整个区域都可以响应手势
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // 允许向上拖拽一定距离，向下拖拽无限制
                                    let translation = value.translation.height
                                    let newDragOffset: CGFloat
                                    
                                    if translation < 0 {
                                        // 向上拖拽：限制在-50到0之间，并增加阻尼效果
                                        newDragOffset = max(-50, translation * 0.3)
                                    } else {
                                        // 向下拖拽：无限制
                                        newDragOffset = translation
                                    }
                                    
                                    // 使用throttle避免过度更新
                                    if abs(newDragOffset - dragOffset) > 0.5 {
                                        dragOffset = newDragOffset
                                    }
                                }
                                .onEnded { value in
                                    let translation = value.translation.height
                                    
                                    // 只有向下拖拽才考虑关闭
                                    if translation > 100 {
                                        dismissSheetWithDrag()
                                    } else {
                                        // 恢复到原位置
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        
                        ScrollView {
                            VStack(spacing: 24) {
                                // 计时器部分
                                TimerDisplayView()
                                
                                // 控制按钮
                                TimerControlButtons(
                                    title: $sessionTitle,
                                    selectedTags: $selectedTags,
                                    description: $sessionDescription,
                                    relatedEvents: $relatedEvents,
                                    onDismiss: { dismissSheet() }
                                )
                                
                                // 专注信息输入
                                FocusInfoInputView(
                                    title: $sessionTitle,
                                    description: $sessionDescription,
                                    selectedTags: $selectedTags,
                                    relatedEvents: $relatedEvents
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 0) // 移除底部padding，让内容延伸到底部
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color(.systemGray6)) // 电纸书风格的浅灰背景
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20)) // 确保内容不溢出圆角边界
                    .blur(radius: isAnimatingOut ? 12 : 0) // 模糊效果
                    .opacity(isAnimatingOut ? 0 : 1) // 透明度动画
                    .scaleEffect(isAnimatingOut ? 0.9 : 1) // 缩放效果
                    .offset(y: offset + dragOffset)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimatingOut) // 模糊动画
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset) // 只对offset应用动画
                }
            }
        }
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                showSheet()
                // 点击专注按钮时，如果当前没有会话，关闭自定义开始时间
                if timerService.sessionState == .idle {
                    UserDefaults.standard.set(false, forKey: "enableCustomStartTime")
                    startFocusSession()
                }
            } else {
                hideSheet()
            }
        }
    }
    
    private func showSheet() {
        isAnimatingOut = false // 重置动画状态
        dragOffset = 0 // 重置拖拽偏移量
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = 0
        }
    }
    
    private func hideSheet() {
        dragOffset = 0 // 重置拖拽偏移量
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = UIScreen.main.bounds.height
        }
    }
    
    private func dismissSheet() {
        // 先启动模糊消失动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isAnimatingOut = true
        }
        
        // 延迟关闭弹窗，让模糊动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPresented = false
            // 重置动画状态
            isAnimatingOut = false
        }
    }
    
    private func dismissSheetWithDrag() {
        // 如果计时器正在运行，显示底部计时条
        if timerService.isRunning || timerService.sessionState == .paused {
            showingBottomTimerBar = true
        }
        
        // 关闭弹窗
        isPresented = false
    }
    
    private func startFocusSession() {
        let title = sessionTitle.isEmpty ? "专注时间" : sessionTitle
        timerService.startSession(title: title, tags: selectedTags)
    }
}

// 计时器显示组件
struct TimerDisplayView: View {
    @EnvironmentObject var timerService: TimerService
    @State private var showingTimerSettings = false
    @AppStorage("circleTimeInterval") private var circleTimeInterval: TimeInterval = 1800 // 默认30分钟一圈
    @AppStorage("showHourFormat") private var showHourFormat = false // 时间格式：true=时:分:秒，false=分:秒
    
    // 计算完成的圆圈数
    private var completedCircles: Int {
        Int(timerService.elapsedTime / circleTimeInterval)
    }
    
    // 计算当前圆圈的进度
    private var currentCircleProgress: Double {
        guard let session = timerService.currentSession else {
            let remainder = timerService.elapsedTime.truncatingRemainder(dividingBy: circleTimeInterval)
            return remainder / circleTimeInterval
        }
        
        // 如果开始时间在未来，不显示进度
        if session.startTime > Date() {
            return 0
        }
        
        let remainder = timerService.elapsedTime.truncatingRemainder(dividingBy: circleTimeInterval)
        return remainder / circleTimeInterval
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 电纸书风格的计时器圆环
            ZStack {
                // 外层装饰边框
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 220, height: 220)
                
                // 内层背景圆
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                // 进度圆环 - 简洁的黑色线条
                Circle()
                    .trim(from: 0, to: currentCircleProgress)
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerService.elapsedTime)
                
                // 中心内容区域
                VStack(spacing: 8) {
                    // 可点击的计时时间 - 电纸书风格字体
                    Button(action: {
                        showingTimerSettings = true
                    }) {
                        Text(getDisplayTime())
                            .font(.system(size: 36, weight: .light, design: .monospaced))
                            .foregroundColor(.black)
                            .tracking(1) // 字符间距
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 状态文字 - 细线条字体
                    Text(getStatusText())
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.black.opacity(0.7))
                        .tracking(0.5)
                        .textCase(.uppercase)
                    
                    // 显示开始时间（如果有当前会话）
                    if let session = timerService.currentSession {
                        let startTimeText = timerService.isStartTimeInFuture() ? 
                            "将于 \(formatStartTime(session.startTime)) 开始" : 
                            "开始于 \(formatStartTime(session.startTime))"
                        
                        Text(startTimeText)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.black.opacity(0.5))
                            .tracking(0.5)
                    }
                }
            }
            .padding(.top, 20)
            
            // 电纸书风格的状态指示
            VStack(spacing: 16) {
                // 运行状态指示 - 简洁的几何形状
                HStack(spacing: 12) {
                    // 状态指示器 - 方形而非圆形
                    Rectangle()
                        .fill(getStatusIndicatorColor())
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: timerService.isRunning)
                    
                    Text(getStatusDisplayText())
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.black.opacity(0.8))
                        .tracking(1)
                        .textCase(.uppercase)
                }
                
                // 完成轮次显示 - 电纸书风格
                if completedCircles > 0 {
                    VStack(spacing: 8) {
                        Text("COMPLETED CYCLES")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                            .tracking(1)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 6) {
                            ForEach(0..<min(completedCircles, 8), id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 6)
                            }
                            
                            if completedCircles > 8 {
                                Text("+\(completedCircles - 8)")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(.black)
                                    .tracking(0.5)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showingTimerSettings) {
            TimerSettingsView(
                circleTimeInterval: $circleTimeInterval,
                showHourFormat: $showHourFormat
            )
            .environmentObject(timerService)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if showHourFormat && hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if showHourFormat {
            return String(format: "0:%02d:%02d", minutes, seconds)
        } else {
            let totalMinutes = Int(timeInterval) / 60
            return String(format: "%02d:%02d", totalMinutes, seconds)
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func getDisplayTime() -> String {
        guard let session = timerService.currentSession else {
            return formatTime(timerService.elapsedTime)
        }
        
        let currentTime = Date()
        if session.startTime > currentTime {
            // 显示距离开始时间的倒计时
            let timeUntilStart = session.startTime.timeIntervalSince(currentTime)
            return "-\(formatTime(timeUntilStart))"
        } else {
            // 正常显示已过时间
            return formatTime(timerService.elapsedTime)
        }
    }
    
    private func getStatusText() -> String {
        guard let session = timerService.currentSession else {
            return timerService.sessionState.rawValue
        }
        
        let currentTime = Date()
        if session.startTime > currentTime {
            return "WAITING"
        } else {
            return timerService.sessionState.rawValue
        }
    }
    
    private func getStatusIndicatorColor() -> Color {
        guard let session = timerService.currentSession else {
            return timerService.isRunning ? Color.black : Color.black.opacity(0.3)
        }
        
        let currentTime = Date()
        if session.startTime > currentTime {
            return Color.black.opacity(0.5) // 等待状态用中等透明度
        } else {
            return timerService.isRunning ? Color.black : Color.black.opacity(0.3)
        }
    }
    
    private func getStatusDisplayText() -> String {
        guard let session = timerService.currentSession else {
            return timerService.isRunning ? "FOCUSING" : "PAUSED"
        }
        
        let currentTime = Date()
        if session.startTime > currentTime {
            return "WAITING"
        } else {
            return timerService.isRunning ? "FOCUSING" : "PAUSED"
        }
    }
}

// 计时器控制按钮
struct TimerControlButtons: View {
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var dataManager: DataManager
    @State private var showingStopAlert = false
    @State private var stopNotes = ""
    
    @Binding var title: String
    @Binding var selectedTags: [String]
    @Binding var description: String
    @Binding var relatedEvents: [String]
    
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 主控制按钮 - 电纸书风格
            Button(action: {
                // 检查是否在等待未来开始时间
                if let session = timerService.currentSession, session.startTime > Date() {
                    // 如果在等待状态，点击可以立即开始
                    // 1. 清除自定义开始时间设置
                    UserDefaults.standard.set(false, forKey: "enableCustomStartTime")
                    // 2. 取消当前会话
                    timerService.cancelSession()
                    // 3. 重新开始一个从当前时间开始的会话
                    let sessionTitle = title.isEmpty ? "专注时间" : title
                    timerService.startSession(title: sessionTitle, tags: selectedTags)
                } else {
                    // 正常的暂停/继续/开始逻辑
                    if timerService.isRunning {
                        timerService.pauseSession()
                    } else if timerService.sessionState == .paused {
                        timerService.resumeSession()
                    } else {
                        // 开始新的会话
                        let sessionTitle = title.isEmpty ? "专注时间" : title
                        timerService.startSession(title: sessionTitle, tags: selectedTags)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    // 图标 - 简洁的几何形状
                    if let session = timerService.currentSession, session.startTime > Date() {
                        // 等待状态显示立即开始图标
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .light))
                    } else if timerService.isRunning {
                        HStack(spacing: 3) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 16)
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 16)
                        }
                    } else {
                        // 播放三角形
                        Image(systemName: timerService.sessionState == .paused ? "play.fill" : "play.fill")
                            .font(.system(size: 18, weight: .light))
                    }
                    
                    Text(getMainButtonText())
                        .font(.system(size: 16, weight: .light))
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 辅助控制按钮 - 电纸书风格
            HStack(spacing: 16) {
                // 重置按钮
                Button(action: {
                    resetTimer()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .light))
                        Text("RESET")
                            .font(.system(size: 10, weight: .light))
                            .tracking(1)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 保存按钮
                Button(action: {
                    saveSession()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .light))
                        Text("SAVE")
                            .font(.system(size: 10, weight: .light))
                            .tracking(1)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(timerService.sessionState == .idle || timerService.elapsedTime < 1 ? .black.opacity(0.3) : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(timerService.sessionState == .idle || timerService.elapsedTime < 1 ? Color.black.opacity(0.3) : Color.black, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(timerService.sessionState == .idle || timerService.elapsedTime < 1)
            }
        }
    }
    
    // 重置计时器（只重置时间，不保存）
    private func resetTimer() {
        timerService.cancelSession()
    }
    
    // 保存专注会话
    private func saveSession() {
        guard timerService.sessionState != .idle && timerService.elapsedTime > 0 else { return }
        
        // 生成唯一标题
        let finalTitle = generateUniqueTitle()
        
        // 计算总时长
        let finalDuration = timerService.elapsedTime
        
        // 创建专注会话
        let session = FocusSession(
            title: finalTitle,
            startTime: timerService.currentSession?.startTime ?? Date(),
            duration: finalDuration,
            tags: selectedTags,
            relatedEvents: relatedEvents,
            notes: description
        )
        
        // 保存到数据管理器
        dataManager.addFocusSession(session)
        
        // 清空输入内容
        title = ""
        description = ""
        selectedTags.removeAll()
        relatedEvents.removeAll()
        
        // 重置计时器状态
        timerService.cancelSession()
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 延迟关闭弹窗，让用户感受到保存成功的反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
    
    // 生成唯一标题
    private func generateUniqueTitle() -> String {
        let baseTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalBaseTitle = baseTitle.isEmpty ? "未命名专注" : baseTitle
        
        // 检查现有标题
        let existingSessions = dataManager.focusSessions
        let existingTitles = Set(existingSessions.map { $0.title })
        
        // 如果标题不存在，直接返回
        if !existingTitles.contains(finalBaseTitle) {
            return finalBaseTitle
        }
        
        // 如果标题已存在，添加数字后缀
        var counter = 2
        var uniqueTitle = "\(finalBaseTitle)\(counter)"
        
        while existingTitles.contains(uniqueTitle) {
            counter += 1
            uniqueTitle = "\(finalBaseTitle)\(counter)"
        }
        
        return uniqueTitle
    }
    
    private func getMainButtonText() -> String {
        if let session = timerService.currentSession, session.startTime > Date() {
            return "START NOW"
        } else if timerService.isRunning {
            return "PAUSE"
        } else if timerService.sessionState == .paused {
            return "RESUME"
        } else {
            return "START"
        }
    }
}

// 专注信息输入组件
struct FocusInfoInputView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedTags: [String]
    @Binding var relatedEvents: [String]
    
    @State private var tagInput = ""
    @State private var eventInput = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // 专注标题 - 电纸书风格
            VStack(alignment: .leading, spacing: 12) {
                Text("FOCUS TITLE")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.black.opacity(0.7))
                    .tracking(1)
                    .textCase(.uppercase)
                
                TextField("What to focus on today?", text: $title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // 描述 - 电纸书风格
            VStack(alignment: .leading, spacing: 12) {
                Text("DESCRIPTION")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.black.opacity(0.7))
                    .tracking(1)
                    .textCase(.uppercase)
                
                TextField("Specific content or goals", text: $description, axis: .vertical)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
                    .lineLimit(3...6)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // 标签系统 - 电纸书风格
            VStack(alignment: .leading, spacing: 12) {
                Text("TAGS #")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.black.opacity(0.7))
                    .tracking(1)
                    .textCase(.uppercase)
                
                EBookTagInputField(
                    input: $tagInput,
                    selectedTags: $selectedTags,
                    placeholder: "Add tags like #work #study"
                )
            }
            
            // 事件系统 - 电纸书风格
            VStack(alignment: .leading, spacing: 12) {
                Text("RELATED EVENTS @")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.black.opacity(0.7))
                    .tracking(1)
                    .textCase(.uppercase)
                
                EBookEventInputField(
                    input: $eventInput,
                    selectedEvents: $relatedEvents,
                    placeholder: "Related events like @meeting @project"
                )
            }
        }
    }
}

// 电纸书风格标签输入组件
struct EBookTagInputField: View {
    @Binding var input: String
    @Binding var selectedTags: [String]
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $input)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        addTag()
                    }
                
                Button("ADD", action: addTag)
                    .font(.system(size: 10, weight: .light))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .black.opacity(0.3) : .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.black.opacity(0.3) : Color.black, lineWidth: 1)
                    )
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 已选择的标签 - 电纸书风格
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        HStack {
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.black)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                    }
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

// 电纸书风格事件输入组件
struct EBookEventInputField: View {
    @Binding var input: String
    @Binding var selectedEvents: [String]
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $input)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        addEvent()
                    }
                
                Button("ADD", action: addEvent)
                    .font(.system(size: 10, weight: .light))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .black.opacity(0.3) : .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.black.opacity(0.3) : Color.black, lineWidth: 1)
                    )
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 已选择的事件 - 电纸书风格
            if !selectedEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(selectedEvents, id: \.self) { event in
                        HStack {
                            Text("@\(event)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.black)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button(action: { removeEvent(event) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                    }
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

// 标签输入组件
struct TagInputField: View {
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
                            .background(Color.blue.opacity(0.1))
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

// 事件输入组件
struct EventInputField: View {
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
                            .background(Color.green.opacity(0.1))
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

// 底部计时条组件
struct BottomTimerBar: View {
    @EnvironmentObject var timerService: TimerService
    @AppStorage("showHourFormat") private var showHourFormat = false // 读取时间格式设置
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 计时显示
            HStack(spacing: 8) {
                // 运行状态指示器
                Circle()
                    .fill(timerService.isRunning ? .green : .orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(timerService.isRunning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: timerService.isRunning)
                
                // 计时时间
                Text(formatTime(timerService.elapsedTime))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                
                // 状态文字
                Text(timerService.sessionState.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 12) {
                // 暂停/继续按钮
                Button(action: {
                    if timerService.isRunning {
                        timerService.pauseSession()
                    } else if timerService.sessionState == .paused {
                        timerService.resumeSession()
                    }
                }) {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(timerService.isRunning ? .orange : .green)
                        .clipShape(Circle())
                }
                
                // 关闭按钮
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(.secondary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 30)
        .clipped() // 防止背景延伸到边界之外
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if showHourFormat && hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if showHourFormat {
            return String(format: "0:%02d:%02d", minutes, seconds)
        } else {
            let totalMinutes = Int(timeInterval) / 60
            return String(format: "%02d:%02d", totalMinutes, seconds)
        }
    }
}

// 计时器设置视图
struct TimerSettingsView: View {
    @Binding var circleTimeInterval: TimeInterval
    @Binding var showHourFormat: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var timerService: TimerService
    @State private var showingCustomInput = false
    @State private var customMinutes = ""
    @State private var selectedStartTime = Date()
    @State private var enableCustomStartTime = false
    
    // 预设的圆圈时间选项（分钟）
    private let timeOptions: [TimeInterval] = [
        15 * 60,    // 15分钟
        25 * 60,    // 25分钟
        30 * 60,    // 30分钟
        45 * 60,    // 45分钟
        60 * 60,    // 1小时
        90 * 60     // 1.5小时
    ]
    
    // 检查当前时间是否为预设选项
    private var isCustomTime: Bool {
        !timeOptions.contains(circleTimeInterval)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("圆形进度条设置") {
                    Text("每一圈完成时间")
                        .font(.headline)
                    
                    ForEach(timeOptions, id: \.self) { timeOption in
                        HStack {
                            Text(formatTimeOption(timeOption))
                            Spacer()
                            if circleTimeInterval == timeOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            circleTimeInterval = timeOption
                        }
                    }
                    
                    // 自定义时间
                    HStack {
                        Text("自定义")
                        Spacer()
                        if isCustomTime {
                            Text(formatTimeOption(circleTimeInterval))
                                .foregroundColor(.blue)
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        Button("设置") {
                            customMinutes = String(Int(circleTimeInterval) / 60)
                            showingCustomInput = true
                        }
                    }
                }
                
                Section("计时开始时间") {
                    Toggle("自定义开始时间", isOn: $enableCustomStartTime)
                        .onChange(of: enableCustomStartTime) { oldValue, newValue in
                            if newValue {
                                selectedStartTime = Date()
                            }
                            // 实时保存设置
                            UserDefaults.standard.set(newValue, forKey: "enableCustomStartTime")
                            
                            // 如果计时器正在运行且关闭了自定义开始时间，更新为当前时间
                            if !newValue && (timerService.sessionState == .running || timerService.sessionState == .paused) {
                                timerService.updateSessionStartTime()
                            }
                        }
                    
                    if enableCustomStartTime {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("选择开始时间")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker(
                                "开始时间",
                                selection: $selectedStartTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .onChange(of: selectedStartTime) { oldValue, newValue in
                                // 实时保存时间设置
                                UserDefaults.standard.set(newValue, forKey: "customTimerStartTime")
                                
                                // 如果计时器正在运行且启用了自定义开始时间，立即更新
                                if enableCustomStartTime && (timerService.sessionState == .running || timerService.sessionState == .paused) {
                                    timerService.updateSessionStartTime()
                                }
                            }
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("设定的开始时间将作为计时器的起始基准时间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("使用当前时间作为开始时间")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        .padding(.vertical, 8)
                    }
                }
                
                Section("显示格式") {
                    Toggle("显示小时格式", isOn: $showHourFormat)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("格式说明:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("关闭:")
                                .font(.caption)
                            Text("MM:SS (如 65:30)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("开启:")
                                .font(.caption)
                            Text("H:MM:SS (如 1:05:30)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("计时器设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("自定义时间", isPresented: $showingCustomInput) {
                TextField("分钟数", text: $customMinutes)
                    .keyboardType(.numberPad)
                
                Button("确定") {
                    if let minutes = Int(customMinutes), minutes > 0 && minutes <= 480 { // 限制在8小时内
                        circleTimeInterval = TimeInterval(minutes * 60)
                    }
                }
                
                Button("取消", role: .cancel) { }
            } message: {
                Text("请输入每一圈的时间（1-480分钟）")
            }
            .onAppear {
                // 每次打开都重新加载设置
                enableCustomStartTime = UserDefaults.standard.bool(forKey: "enableCustomStartTime")
                if let savedStartTime = UserDefaults.standard.object(forKey: "customTimerStartTime") as? Date {
                    selectedStartTime = savedStartTime
                } else {
                    selectedStartTime = Date()
                }
            }
        }
    }
    
    private func formatTimeOption(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(minutes)分钟"
        }
    }
}

#Preview {
    ContentView()
}
