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
    @State private var showingActionSheet = false
    @State private var showingNewIdea = false
    @State private var showingFocusTimer = false
    @State private var showingGlobalSearch = false
    
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
                // 顶部标签栏
                TopTabBar(selectedTab: $selectedTab)
                
                // 主内容区域
                TabView(selection: $selectedTab) {
                    TimelineView()
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
            
            // 悬浮操作栏
            VStack {
                Spacer()
                FloatingActionBar(
                    onHomeAction: { selectedTab = .timeline },
                    onActionSheetToggle: { showingActionSheet.toggle() },
                    onSearchAction: { showingGlobalSearch = true }
                )
                .padding(.bottom, 40)
            }
        }
        .environmentObject(dataManager)
        .environmentObject(timerService)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("选择操作"),
                buttons: [
                    .default(Text("新建想法")) {
                        showingNewIdea = true
                    },
                    .default(Text("专注时间")) {
                        showingFocusTimer = true
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
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
            }
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

// 单个标签按钮
struct TabButton: View {
    let tab: ContentView.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(tab.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                // 选中指示器
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 悬浮操作栏
struct FloatingActionBar: View {
    let onHomeAction: () -> Void
    let onActionSheetToggle: () -> Void
    let onSearchAction: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 首页按钮
            Button(action: onHomeAction) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            
            // 中间操作按钮
            Button(action: onActionSheetToggle) {
                HStack {
                    VStack(spacing: 2) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                            Text("想法")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text("专注")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            
            // 搜索按钮
            Button(action: onSearchAction) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    ContentView()
}
