//
//  ContentView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

// 滚动偏移监听
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var timerService = TimerService()
    @State private var selectedTab: MainTab = .timeline
    @State private var showingNewIdea = false
    @State private var showingFocusTimer = false
    @State private var showingGlobalSearch = false
    @State private var isScrolled = false
    
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
                // 默认状态的顶部标签栏
                if !isScrolled {
                    TopTabBar(selectedTab: $selectedTab, isFloating: false)
                }
                
                // 主内容区域
                ScrollViewReader { proxy in
                    TabView(selection: $selectedTab) {
                        ScrollView {
                            LazyVStack {
                                // 添加滚动检测区域
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, 
                                                  value: geometry.frame(in: .named("scroll")).minY)
                                }
                                .frame(height: 0)
                                
                                // 内容区域
                                TimelineView()
                            }
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isScrolled = value < -20
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
            
            // 悬浮状态的顶部标签栏
            if isScrolled {
                VStack {
                    TopTabBar(selectedTab: $selectedTab, isFloating: true)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
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
        .shadow(color: .black.opacity(isFloating ? 0.05 : 0), radius: isFloating ? 8 : 0, x: 0, y: isFloating ? 4 : 0)
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

#Preview {
    ContentView()
}
