//
//  NewTaskView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct NewTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedPriority: Task.TaskPriority = .medium
    @State private var selectedTags: [String] = []
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var newTagName = ""
    @State private var showingTagInput = false
    
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
                        ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
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
                
                Section(header: Text("标签")) {
                    if !selectedTags.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80))
                        ], spacing: 8) {
                            ForEach(selectedTags, id: \.self) { tag in
                                TagView(tag: tag, isSelected: true) {
                                    selectedTags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                    
                    Button("添加标签") {
                        showingTagInput = true
                    }
                }
                
                if !dataManager.tags.isEmpty {
                    Section(header: Text("选择已有标签")) {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80))
                        ], spacing: 8) {
                            ForEach(dataManager.tags, id: \.id) { tag in
                                TagView(
                                    tag: tag.name,
                                    isSelected: selectedTags.contains(tag.name)
                                ) {
                                    if selectedTags.contains(tag.name) {
                                        selectedTags.removeAll { $0 == tag.name }
                                    } else {
                                        selectedTags.append(tag.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("新建任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
        .alert("添加标签", isPresented: $showingTagInput) {
            TextField("标签名称", text: $newTagName)
            Button("添加") {
                if !newTagName.isEmpty && !selectedTags.contains(newTagName) {
                    selectedTags.append(newTagName)
                    
                    // 添加到全局标签列表
                    let newTag = Tag(name: newTagName)
                    dataManager.addTag(newTag)
                    
                    newTagName = ""
                }
            }
            Button("取消", role: .cancel) {
                newTagName = ""
            }
        }
    }
    
    private func saveTask() {
        let task = Task(
            title: title,
            content: content,
            tags: selectedTags,
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority
        )
        
        dataManager.addTask(task)
        
        // 增加标签使用次数
        for tagName in selectedTags {
            dataManager.incrementTagUsage(tagName)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct TagView: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewTaskView()
        .environmentObject(DataManager.shared)
}
