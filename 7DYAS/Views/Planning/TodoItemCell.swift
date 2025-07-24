import SwiftUI

struct TodoItemCell: View {
    let task: Task
    let expanded: Bool
    let onExpand: () -> Void
    let onCheck: () -> Void
    
    // 添加本地状态，用于控制展开/收起动画
    @State private var isExpanded: Bool
    
    // 添加初始化方法，同步外部和内部状态
    init(task: Task, expanded: Bool, onExpand: @escaping () -> Void, onCheck: @escaping () -> Void) {
        self.task = task
        self.expanded = expanded
        self.onExpand = onExpand
        self.onCheck = onCheck
        // 初始化本地状态
        self._isExpanded = State(initialValue: expanded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 主要内容行
            HStack(spacing: 12) {
                // 完成按钮 (独立)
                Button(action: onCheck) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : (task.isDeferred ? .red : .gray))
                }
                .buttonStyle(PlainButtonStyle())
                
                // 任务标题和信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    // 任务标签和时间信息
                    HStack {
                        if let range = task.dateRange, range.cycle != .day, range.selectedDays.count > 1 {
                            Text(range.cycle == .week ? "周计划" : range.cycle == .month ? "月计划" : "年计划")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                        
                        if task.isCompleted, let _ = task.completedTime {
                            if let _ = task.createdDate as Date?, let duration = task.duration {
                                let minutes = Int(duration) / 60
                                let seconds = Int(duration) % 60
                                Text("耗时\(minutes)分\(seconds)秒")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("已完成")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 展开/收起按钮 - 使用本地状态
                Button(action: {
                    // 使用本地动画，不影响外部
                    withAnimation(.easeInOut(duration: 0.35)) {
                        // 同步本地状态
                        isExpanded.toggle()
                        // 调用外部回调
                        onExpand()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 展开的详细信息 - 使用本地状态
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !task.content.isEmpty {
                        Text(task.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !task.atItems.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(task.atItems, id: \.self) { at in
                                Text("@" + at)
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 4)
                                    .background(Color.purple.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if !task.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(task.tags, id: \.self) { tag in
                                Text("#" + tag)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 4)
                                    .background(Color.blue.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Text("类型：\(task.type.rawValue)  周期：\(task.cycle.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if task.isCompleted, let completedTime = task.completedTime {
                        Text("完成时间：\(completedTime, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Text("创建时间：\(task.createdDate, formatter: dateFormatter)")
                        .font(.caption2)
                        .foregroundColor(task.isDeferred ? .red : .secondary)
                }
                .padding(.leading, 32)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            // 使用本地动画，不影响外部
            withAnimation(.easeInOut(duration: 0.35)) {
                // 同步本地状态
                isExpanded.toggle()
                // 调用外部回调
                onExpand()
            }
        }
        // 监听外部状态变化，同步到本地状态
        .onChange(of: expanded) { oldValue, newValue in
            if isExpanded != newValue {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isExpanded = newValue
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }
} 