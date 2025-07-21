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
            VStack(spacing: 0) {
                // 固定样式的顶部标签栏
                TopTabBar(selectedTab: $selectedTab, isFloating: false)
                
                // 主内容区域
                ScrollViewReader { proxy in
                    TabView(selection: $selectedTab) {
                        ScrollView {
                            LazyVStack {
                                // 内容区域
                                TimelineView(selectedDate: $timelineSelectedDate)
                            }
                        }
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
            }
            
            // 时间线视图的悬浮日期栏 - 使用模糊动画组件
            VStack {
                Spacer()
                    .frame(height: 140) // 固定距离，适配固定顶栏
                
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
                    .frame(height: 140) // 固定距离，适配固定顶栏
                
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
                    .padding(.bottom, 10)
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
        .ignoresSafeArea(.container, edges: .bottom)
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
    let isFloating: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 应用标题
            HStack {
                Text("7DAYS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 可以在这里添加设置按钮或其他功能
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
            
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
                .padding(.bottom, 8)
            }
            
            // 渐变透明底边 (仅悬浮模式显示)
            if isFloating {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear.opacity(0.3), location: 0),
                        .init(color: Color.clear.opacity(0.1), location: 0.5),
                        .init(color: Color.clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 8)
            } else {
                Divider()
            }
        }
        .background(
            Group {
                if isFloating {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                } else {
                    Color(.systemBackground)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

// 单个标签按钮
struct TabButton: View {
    let tab: ContentView.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: tab.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                    
                    Text(tab.title)
                        .font(.headline)
                        .fontWeight(isSelected ? .bold : .semibold)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                
                // 选中指示器
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(minWidth: 90)
            .padding(.horizontal, 12)
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
        formatter.dateFormat = "MM月dd日 EEEE"
        return formatter
    }
    
    var body: some View {
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
            TimelineFloatingFocusStats()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    
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
                        // 拖拽指示器 - 只有这个区域可以拖拽窗口
                        VStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: 40, height: 4)
                        }
                        .frame(height: 40) // 设置拖拽区域高度
                        .frame(maxWidth: .infinity) // 横向填满以便拖拽
                        .background(Color.clear) // 透明背景扩大触摸区域
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
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxHeight: maxHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThickMaterial)
                    )
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
                // 点击专注按钮时自动开始计时
                if timerService.sessionState == .idle {
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
        let remainder = timerService.elapsedTime.truncatingRemainder(dividingBy: circleTimeInterval)
        return remainder / circleTimeInterval
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 计时器圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: currentCircleProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerService.elapsedTime)
                
                VStack(spacing: 4) {
                    // 可点击的计时时间
                    Button(action: {
                        showingTimerSettings = true
                    }) {
                        Text(formatTime(timerService.elapsedTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(timerService.sessionState.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20) // 增加顶部边距，避免与拖拽手柄重叠
            
            // 状态指示和圆圈完成标记
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(timerService.isRunning ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(timerService.isRunning ? "专注中" : "已暂停")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 圆圈完成标记
                if completedCircles > 0 {
                    HStack(spacing: 4) {
                        Text("完成轮次:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<min(completedCircles, 10), id: \.self) { _ in
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 6, height: 6)
                            }
                            
                            if completedCircles > 10 {
                                Text("+\(completedCircles - 10)")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingTimerSettings) {
            TimerSettingsView(
                circleTimeInterval: $circleTimeInterval,
                showHourFormat: $showHourFormat
            )
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
        VStack(spacing: 16) {
            // 第一行：暂停/继续按钮
            Button(action: {
                if timerService.isRunning {
                    timerService.pauseSession()
                } else if timerService.sessionState == .paused {
                    timerService.resumeSession()
                } else {
                    // 开始新的会话
                    let sessionTitle = title.isEmpty ? "专注时间" : title
                    timerService.startSession(title: sessionTitle, tags: selectedTags)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                    Text(timerService.isRunning ? "暂停" : 
                         (timerService.sessionState == .paused ? "继续" : "开始"))
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: timerService.isRunning ? [.orange, .red] : [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            
            // 第二行：重置和保存按钮
            HStack(spacing: 12) {
                // 重置按钮
                Button(action: {
                    resetTimer()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("重置")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.gray, .secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                
                // 保存按钮
                Button(action: {
                    saveSession()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("保存")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
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
        VStack(spacing: 20) {
            // 专注标题
            VStack(alignment: .leading, spacing: 8) {
                Text("专注标题")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("今天要专注什么？", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            // 描述
            VStack(alignment: .leading, spacing: 8) {
                Text("描述")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("专注的具体内容或目标", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .font(.body)
            }
            
            // 标签系统 (#)
            VStack(alignment: .leading, spacing: 8) {
                Text("标签 #")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TagInputField(
                    input: $tagInput,
                    selectedTags: $selectedTags,
                    placeholder: "添加标签，如 #工作 #学习"
                )
            }
            
            // 事件系统 (@)
            VStack(alignment: .leading, spacing: 8) {
                Text("关联事件 @")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                EventInputField(
                    input: $eventInput,
                    selectedEvents: $relatedEvents,
                    placeholder: "关联事件，如 @会议 @项目"
                )
            }
        }
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
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
        .padding(.horizontal, 30)
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
    @State private var showingCustomInput = false
    @State private var customMinutes = ""
    
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
