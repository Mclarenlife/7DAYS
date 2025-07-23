import Foundation
import SwiftUI

class PlanningViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var showCompleted: Bool = false
    @Published var expandedTaskIDs: Set<UUID> = []
    
    private let dataManager = DataManager.shared
    
    init() {
        self.tasks = dataManager.tasks
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
        reloadTasks()
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
                    return Calendar.current.isDate(date, inSameDayAs: task.dueDate ?? date)
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
                return Calendar.current.isDate(date, inSameDayAs: task.dueDate ?? date)
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
    
    // 延期逻辑、每日循环等可在此扩展
} 