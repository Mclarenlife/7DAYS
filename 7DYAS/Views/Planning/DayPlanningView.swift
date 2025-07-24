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
                ScrollView {
                    LazyVStack(spacing: 12) {
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
                        }
                        
                        // 已完成任务列表
                        if !viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle).isEmpty {
                            Divider().padding(.vertical, 8)
                            
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
                            
                            // 已完成任务列表
                            if showCompletedLocal {
                                VStack(spacing: 12) {
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    // 确保所有子视图的位置变化都有动画
                    .animation(.easeInOut(duration: 0.35), value: viewModel.expandedTaskIDs)
                }
                .onChange(of: viewModel.tasks.count) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("bottom_stats", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
} 