import SwiftUI

struct TodoItemCell: View {
    let task: TodoTask
    let expanded: Bool
    let onExpand: () -> Void
    let onCheck: () -> Void
    
    // 添加本地状态，用于控制展开/收起动画
    @State private var isExpanded: Bool
    // 获取当前颜色模式
    @Environment(\.colorScheme) private var colorScheme
    
    // 添加初始化方法，同步外部和内部状态
    init(task: TodoTask, expanded: Bool, onExpand: @escaping () -> Void, onCheck: @escaping () -> Void) {
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
                    HStack(alignment: .center, spacing: 4) {
                        // 优先级前缀（叹号）
                        if !task.priority.prefix.isEmpty {
                            Text(task.priority.prefix)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        // 任务标题
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                    }
                    
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
                    }
                }
                
                Spacer()
                
                // 已完成事项右侧显示完成用时
                if task.isCompleted, let _ = task.completedTime, let duration = task.duration {
                    let hours = Int(duration) / 3600
                    let minutes = (Int(duration) % 3600) / 60
                    let seconds = Int(duration) % 60
                    
                    if hours > 0 {
                        Text("耗时\(hours)时\(minutes)分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if minutes > 0 {
                        Text("耗时\(minutes)分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("耗时\(seconds)秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
                    
                    // 显示创建日期
                    Text("创建时间：\(task.createdDate, formatter: dateFormatter)")
                        .font(.caption2)
                        .foregroundColor(task.isDeferred ? .red : .secondary)
                    
                    // 显示截止日期（如果有）- 移到创建日期的下方
                    if let dueDate = task.dueDate {
                        Text("截止日期：\(dueDate, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    
                    if task.isCompleted, let completedTime = task.completedTime {
                        Text("完成时间：\(completedTime, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.leading, 32)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        // 在深色模式下使用纯黑色背景，浅色模式下保持原来的背景色
        .background(colorScheme == .dark ? Color.black : Color(.secondarySystemGroupedBackground))
        .contentShape(Rectangle())
        .overlay(
            // 自定义分隔线，高度更小，从中间到两边渐变透明
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.gray.opacity(0.3), location: 0.1),
                    .init(color: Color.gray.opacity(0.5), location: 0.5),
                    .init(color: Color.gray.opacity(0.3), location: 0.9),
                    .init(color: Color.clear, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.5) // 缩小高度
            .padding(.horizontal, 10), // 让两侧有一定的内边距
            alignment: .bottom
        )
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
        .onChange(of: expanded) { newValue in
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