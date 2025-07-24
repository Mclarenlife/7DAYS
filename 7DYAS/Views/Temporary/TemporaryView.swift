//
//  TemporaryView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct TemporaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewIdea = false
    
    private var unarchiveIdeas: [TemporaryIdea] {
        dataManager.getUnarchiveIdeas()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 简化的顶部导航
            TemporaryHeader(onNewIdea: { showingNewIdea = true })
            
            if unarchiveIdeas.isEmpty {
                EmptyTemporaryView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(unarchiveIdeas) { idea in
                            TemporaryIdeaCard(idea: idea)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .sheet(isPresented: $showingNewIdea) {
            NewIdeaView()
        }
    }
}

struct TemporaryHeader: View {
    let onNewIdea: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("记录灵感，快速捕捉想法")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onNewIdea) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

struct EmptyTemporaryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("暂无想法记录")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("快速记录你的灵感和临时想法")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TemporaryIdeaCard: View {
    let idea: TemporaryIdea
    @EnvironmentObject var dataManager: DataManager
    @State private var showingActionSheet = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 内容
            Text(idea.content)
                .font(.body)
                .lineSpacing(4)
            
            // 标签和时间
            HStack {
                if !idea.tags.isEmpty {
                    HStack {
                        ForEach(idea.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        
                        if idea.tags.count > 3 {
                            Text("+\(idea.tags.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Spacer()
                }
                
                Text(dateFormatter.string(from: idea.createdDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 优先级和操作
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(idea.priority.color)
                        .frame(width: 8, height: 8)
                    
                    Text(idea.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("选择操作"),
                buttons: [
                    .default(Text("转为任务")) {
                        convertToTask()
                    },
                    .default(Text("归档")) {
                        dataManager.archiveTemporaryIdea(idea)
                    },
                    .destructive(Text("删除")) {
                        dataManager.deleteTemporaryIdea(idea)
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    private func convertToTask() {
        let task = TodoTask(
            title: String(idea.content.prefix(50)), // 取前50个字符作为标题
            content: idea.content,
            tags: idea.tags,
            priority: idea.priority
        )
        
        dataManager.addTask(task)
        dataManager.archiveTemporaryIdea(idea)
    }
}

struct NewIdeaView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var content = ""
    @State private var selectedTags: [String] = []
    @State private var selectedPriority: TodoTask.TaskPriority = .medium
    @State private var newTagName = ""
    @State private var showingTagInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 内容输入区域
                VStack(alignment: .leading, spacing: 16) {
                    Text("记录你的想法")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Form {
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
                                ForEach(dataManager.tags.prefix(10), id: \.id) { tag in
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
            }
            .navigationTitle("新建想法")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveIdea()
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    
    private func saveIdea() {
        let idea = TemporaryIdea(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags,
            priority: selectedPriority
        )
        
        dataManager.addTemporaryIdea(idea)
        
        // 增加标签使用次数
        for tagName in selectedTags {
            dataManager.incrementTagUsage(tagName)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    TemporaryView()
        .environmentObject(DataManager.shared)
}
