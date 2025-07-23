import SwiftUI

struct DayPlanningView: View {
    let selectedDate: Date
    let selectedSubView: ContentView.DaySubViewType
    @EnvironmentObject var viewModel: PlanningViewModel
    
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
                        ForEach(viewModel.uncompletedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle)) { task in
                            TodoItemCell(task: task, expanded: viewModel.expandedTaskIDs.contains(task.id)) {
                                viewModel.toggleExpand(task)
                            } onCheck: {
                                viewModel.toggleTaskCompletion(task)
                            }
                        }
                        if !viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle).isEmpty {
                            Divider().padding(.vertical, 8)
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    viewModel.showCompleted.toggle()
                                }
                            }) {
                                HStack {
                                    Text(viewModel.showCompleted ? "收起已完成" : "展开已完成")
                                    Image(systemName: viewModel.showCompleted ? "chevron.up" : "chevron.down")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            if viewModel.showCompleted {
                                ForEach(viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle)) { task in
                                    TodoItemCell(task: task, expanded: viewModel.expandedTaskIDs.contains(task.id)) {
                                        viewModel.toggleExpand(task)
                                    } onCheck: {
                                        viewModel.toggleTaskCompletion(task)
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                        removal: .opacity.combined(with: .scale(scale: 1.05))
                                    ))
                                }
                            }
                        }
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