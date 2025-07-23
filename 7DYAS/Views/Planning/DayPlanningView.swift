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
            // 内容区域切换由外部控制
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.uncompletedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle)) { task in
                        TodoItemCell(task: task, expanded: viewModel.expandedTaskIDs.contains(task.id)) {
                            viewModel.toggleExpand(task)
                        } onCheck: {
                            viewModel.toggleTaskCompletion(task)
                        }
                    }
                    if !viewModel.completedTasksFor(date: selectedDate, type: currentTaskType, cycle: currentCycle).isEmpty {
                        Divider().padding(.vertical, 8)
                        Button(action: { viewModel.showCompleted.toggle() }) {
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
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
} 