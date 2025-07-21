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
    
    // 时间线日期栏状态
    @State private var timelineSelectedDate = Date()
    @State private var showingTimelineDatePicker = false
    
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
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
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
                        
                        PlanningView()
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
            
            // 时间线视图的悬浮日期栏
            if selectedTab == .timeline {
                VStack {
                    Spacer()
                        .frame(height: 140) // 固定距离，适配固定顶栏
                    
                    TimelineFloatingDateBar(
                        selectedDate: $timelineSelectedDate,
                        showingDatePicker: $showingTimelineDatePicker
                    )
                    
                    Spacer()
                }
            }
            
            // 底部悬浮操作栏
            VStack {
                Spacer()
                FloatingActionBar(
                    onHomeAction: { selectedTab = .timeline },
                    onIdeaAction: { showingNewIdea = true },
                    onFocusAction: { showingFocusTimer = true },
                    onSearchAction: { showingGlobalSearch = true }
                )
                .padding(.bottom, 40)
            }
        }
        .environmentObject(dataManager)
        .environmentObject(timerService)
        .sheet(isPresented: $showingNewIdea) {
            NewIdeaView()
        }
        .sheet(isPresented: $showingFocusTimer) {
            FocusTimerView()
        }
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView()
        }
        .sheet(isPresented: $showingTimelineDatePicker) {
            TimelineDatePickerSheet(selectedDate: $timelineSelectedDate)
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
        .padding(.horizontal, 16) // 左右留边距
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

#Preview {
    ContentView()
}
