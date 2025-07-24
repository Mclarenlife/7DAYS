//
//  TaskDetailView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct TaskDetailView: View {
    let task: TodoTask
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和状态
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(task.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                            
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 12, height: 12)
                        }
                        
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            
                            Text(task.isCompleted ? "已完成" : "未完成")
                                .font(.subheadline)
                                .foregroundColor(task.isCompleted ? .green : .orange)
                            
                            Spacer()
                            
                            Text(task.priority.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.priority.color.opacity(0.2))
                                .foregroundColor(task.priority.color)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 描述内容
                    if !task.content.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("描述")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(task.content)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 时间信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("时间信息")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            InfoRow(
                                icon: "calendar.badge.plus",
                                title: "创建时间",
                                value: dateFormatter.string(from: task.createdDate)
                            )
                            
                            if let dueDate = task.dueDate {
                                InfoRow(
                                    icon: "clock.badge.exclamationmark",
                                    title: "截止时间",
                                    value: dateFormatter.string(from: dueDate),
                                    valueColor: isOverdue(dueDate) ? .red : .primary
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 标签
                    if !task.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("标签")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(task.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: { dataManager.toggleTaskCompletion(task) }) {
                            HStack {
                                Image(systemName: task.isCompleted ? "arrow.counterclockwise" : "checkmark")
                                Text(task.isCompleted ? "标记为未完成" : "标记为完成")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(task.isCompleted ? Color.orange : Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { showingEditView = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("编辑")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("任务详情")
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingEditView) {
            EditTaskView(task: task)
        }
        .alert("删除任务", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                dataManager.deleteTask(task)
                presentationMode.wrappedValue.dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除这个任务吗？此操作无法撤销。")
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct EditTaskView: View {
    let task: TodoTask
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title: String
    @State private var content: String
    @State private var selectedPriority: TodoTask.TaskPriority
    @State private var selectedTags: [String]
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    
    init(task: TodoTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _content = State(initialValue: task.content)
        _selectedPriority = State(initialValue: task.priority)
        _selectedTags = State(initialValue: task.tags)
        _dueDate = State(initialValue: task.dueDate)
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("任务标题", text: $title)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("描述")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $selectedPriority) {
                        ForEach(TodoTask.TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("截止日期")) {
                    Toggle("设置截止日期", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("截止日期", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveChanges()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.content = content
        updatedTask.priority = selectedPriority
        updatedTask.tags = selectedTags
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        
        dataManager.updateTask(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    TaskDetailView(task: TodoTask(title: "示例任务", content: "这是一个示例任务的描述内容"))
        .environmentObject(DataManager.shared)
}
