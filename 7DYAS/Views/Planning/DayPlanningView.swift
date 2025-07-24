import SwiftUI

struct DayPlanningView: View {
    let selectedDate: Date
    let selectedSubView: ContentView.DaySubViewType
    @EnvironmentObject var viewModel: PlanningViewModel
    // 添加一个状态变量来强制视图刷新
    @State private var refreshID = UUID()
    // 本地管理已完成列表的展开状态，而不是使用viewModel中的状态
    @State private var showCompletedLocal = false
    
    // 添加动画命名空间，用于协调所有动画
    @Namespace private var animation
    
    // 添加滚动相关状态
    @Binding var showDateBar: Bool
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollDirection: ScrollDirection = .none
    @State private var isInBounceRegion: Bool = false // 用于检测回弹状态
    @State private var initialContentOffset: CGFloat = 0 // 用于记录初始内容偏移
    
    enum ScrollDirection {
        case up, down, none
    }
    
    private var currentTaskType: TaskType {
        switch selectedSubView {
        case .planning: return .plan
        case .dailyRoutine: return .dailyRoutine
        case .journal: return .journal
        }
    }
    
    private var currentCycle: TaskCycle { .day }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                // 使用监听器包装ScrollView
                ObservableScrollView(onOffsetChange: { offset, size in
                    // 内容实际偏移量 - 首次获取时保存为初始值
                    if initialContentOffset == 0 {
                        initialContentOffset = offset
                    }
                    
                    // 检测是否在回弹区域 - 当offset比初始值大时，说明处于下拉状态
                    let isCurrentlyInBounceRegion = offset > initialContentOffset + 10
                    
                    // 如果刚刚退出回弹区域，忽略一次滚动事件
                    if isInBounceRegion && !isCurrentlyInBounceRegion {
                        // 只更新状态，不触发日期栏变化
                        isInBounceRegion = false
                        lastScrollOffset = offset
                        return
                    }
                    
                    // 更新回弹区域状态
                    isInBounceRegion = isCurrentlyInBounceRegion
                    
                    // 如果在回弹区域，不处理滚动事件
                    if isInBounceRegion {
                        lastScrollOffset = offset
                        return
                    }
                    
                    // 计算滚动方向 - 注意：负值表示向上滚动，正值表示向下滚动
                    let delta = offset - lastScrollOffset
                    
                    // 设置阈值以减少灵敏度
                    if abs(delta) > 3 {
                        // 内容向上滚动(手指向上滑) - 隐藏日期栏
                        if delta < 0 {
                            if scrollDirection != .up {
                                scrollDirection = .up
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.2)) {
                                    showDateBar = false
                                }
                            }
                        }
                        // 内容向下滚动(手指向下滑) - 显示日期栏
                        else {
                            if scrollDirection != .down {
                                scrollDirection = .down
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.2)) {
                                    showDateBar = true
                                }
                            }
                        }
                    }
                    
                    // 保存最后的滚动位置
                    lastScrollOffset = offset
                }) {
                    LazyVStack(spacing: 0) {
                        Color.clear.frame(height: 190)
                        
                        // 未完成任务列表
                        ForEach(viewModel.uncompletedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle)) { task in
                            TodoItemCell(task: task, expanded: viewModel.expandedTaskIDs.contains(task.id)) {
                                // 使用全局动画，确保所有元素平滑移动
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    viewModel.toggleExpand(task)
                                    refreshID = UUID()
                                }
                            } onCheck: {
                                viewModel.toggleTaskCompletion(task)
                                refreshID = UUID()
                                // 如果任务被标记为完成，自动展开已完成列表
                                if task.isCompleted {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        showCompletedLocal = true
                                    }
                                }
                            }
                            .matchedGeometryEffect(id: "task_\(task.id)", in: animation)
                            .id("task_\(task.id)") // 添加ID标识，用于滚动定位
                        }
                        
                        // 已完成任务列表
                        if !viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle).isEmpty {
                            // 展开/收起按钮
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    showCompletedLocal.toggle()
                                }
                            }) {
                                HStack {
                                    Text(showCompletedLocal ? "收起已完成" : "展开已完成")
                                    Image(systemName: showCompletedLocal ? "chevron.up" : "chevron.down")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.top, 26) // 添加上边距
                            
                            // 已完成任务列表
                            if showCompletedLocal {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle)) { task in
                                        TodoItemCell(task: task, expanded: viewModel.expandedTaskIDs.contains(task.id)) {
                                            // 使用全局动画，确保所有元素平滑移动
                                            withAnimation(.easeInOut(duration: 0.35)) {
                                                viewModel.toggleExpand(task)
                                                refreshID = UUID()
                                            }
                                        } onCheck: {
                                            viewModel.toggleTaskCompletion(task)
                                            refreshID = UUID()
                                        }
                                        .matchedGeometryEffect(id: "task_\(task.id)", in: animation)
                                    }
                                }
                                .transition(.opacity) // 只对整个列表应用淡入淡出，内部项目保持位置
                            }
                        }
                        
                        // 底部统计信息
                        VStack(spacing: 20) {
                            Color.clear.frame(height: 60)
                            VStack(spacing: 8) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("至今共完成\(viewModel.tasks.filter { $0.isCompleted }.count)项计划")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            Color.clear.frame(height: 100)
                        }
                        .id("bottom_stats")
                    }
                    .padding(.vertical, 16)
                    // 确保所有子视图的位置变化都有动画
                    .animation(.easeInOut(duration: 0.35), value: viewModel.expandedTaskIDs)
                }
                .onChange(of: viewModel.tasks.count) { _, _ in
                    // 检查是否有新添加的任务
                    if let lastAddedTaskID = viewModel.lastAddedTaskID {
                        // 延迟一点执行，确保视图已更新
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // 只滚动到新添加的任务，而不是底部
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("task_\(lastAddedTaskID)", anchor: .center)
                            }
                            // 清除最近添加的任务ID，避免重复滚动
                            viewModel.lastAddedTaskID = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            // 确保初始状态下日期栏可见
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.2)) {
                showDateBar = true
            }
        }
    }
}

// 可观察滚动视图 - 监听内容区域的滚动
struct ObservableScrollView<Content: View>: View {
    let content: Content
    let onOffsetChange: (CGFloat, CGSize) -> Void
    
    init(
        onOffsetChange: @escaping (CGFloat, CGSize) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onOffsetChange = onOffsetChange
    }
    
    var body: some View {
        ScrollView {
            offsetReader
            content
                .padding(.top, -8) // 抵消offsetReader的高度
        }
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .global).minY
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    onOffsetChange(value, proxy.size)
                }
                .frame(height: 0) // 使其高度为零，不占用空间
        }
    }
}

// 滚动偏移首选项键
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 