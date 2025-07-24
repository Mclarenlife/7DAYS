import Foundation
import SwiftUI
import Combine

class PlanningViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var showCompleted: Bool = false
    @Published var expandedTaskIDs: Set<UUID> = []
    
    private var dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.tasks = dataManager.tasks
       
        // 监听DataManager中的tasks变化
        dataManager.$tasks
            .sink { [weak self] updatedTasks in
                self?.tasks = updatedTasks
            }
            .store(in: &cancellables)
    }
    
    func reloadTasks() {
        self.tasks = dataManager.tasks
    }
    
    func addTask(_ task: Task) {
        dataManager.addTask(task)
        reloadTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        dataManager.toggleTaskCompletion(task)
        // 强制刷新任务列表，确保视图更新
        DispatchQueue.main.async {
            self.reloadTasks()
            // 移除自动展开已完成列表的逻辑，由视图层处理
        }
    }
    
    func toggleExpand(_ task: Task) {
        if expandedTaskIDs.contains(task.id) {
            expandedTaskIDs.remove(task.id)
        } else {
            expandedTaskIDs.insert(task.id)
        }
    }
    
    func tasksFor(date: Date, type: TaskType, cycle: TaskCycle) -> [Task] {
        // 支持多周期、多日期、延期、每日循环等逻辑
        return tasks.filter { task in
            guard task.type == type, task.cycle == cycle else { return false }
            // 日/周/月/年周期判断
            if let range = task.dateRange {
                switch range.cycle {
                case .day:
                    return Calendar.current.isDate(date, inSameDayAs: task.createdDate)
                case .week:
                    let weekday = Calendar.current.component(.weekday, from: date)
                    return range.selectedDays.contains(weekday)
                case .month:
                    let day = Calendar.current.component(.day, from: date)
                    return range.selectedDays.contains(day)
                case .year:
                    let month = Calendar.current.component(.month, from: date)
                    return range.selectedDays.contains(month)
                }
            } else {
                // 兼容旧数据
                return Calendar.current.isDate(date, inSameDayAs: task.createdDate)
            }
        }.sorted(by: { $0.createdDate < $1.createdDate })
    }
    
    func completedTasksFor(date: Date, type: TaskType, cycle: TaskCycle) -> [Task] {
        return tasksFor(date: date, type: type, cycle: cycle).filter { $0.isCompleted }
    }
    
    func uncompletedTasksFor(date: Date, type: TaskType, cycle: TaskCycle) -> [Task] {
        return tasksFor(date: date, type: type, cycle: cycle).filter { !$0.isCompleted }
    }
    
    var tags: [Tag] {
        dataManager.tags
    }
    func incrementTagUsage(_ tagName: String) {
        dataManager.incrementTagUsage(tagName)
    }
    
    func addTag(_ tag: Tag) {
        dataManager.addTag(tag)
    }
    
    // 手动触发未完成任务顺延
    func deferUncompletedTasks() {
        dataManager.deferUncompletedTasksToToday()
        reloadTasks()
    }
    
    // 延期逻辑、每日循环等可在此扩展
} 