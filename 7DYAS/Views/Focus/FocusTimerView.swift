//
//  FocusTimerView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct FocusTimerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var timerService: TimerService
    @EnvironmentObject var dataManager: DataManager
    
    @State private var sessionTitle = ""
    @State private var selectedTags: [String] = []
    @State private var relatedTask: Task?
    @State private var notes = ""
    @State private var showingTaskPicker = false
    @State private var showingStopAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if timerService.sessionState == .idle {
                    // 开始前的设置界面
                    StartSessionView(
                        sessionTitle: $sessionTitle,
                        selectedTags: $selectedTags,
                        relatedTask: $relatedTask,
                        showingTaskPicker: $showingTaskPicker,
                        onStart: startSession
                    )
                } else {
                    // 专注进行中的界面
                    RunningSessionView(
                        onPause: timerService.pauseSession,
                        onResume: timerService.resumeSession,
                        onStop: { showingStopAlert = true }
                    )
                }
            }
            .navigationTitle("专注时间")
            .navigationBarItems(
                leading: Button("取消") {
                    if timerService.sessionState != .idle {
                        timerService.cancelSession()
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(selectedTask: $relatedTask)
        }
        .alert("结束专注", isPresented: $showingStopAlert) {
            TextField("添加备注", text: $notes)
            Button("结束") {
                timerService.stopSession(notes: notes)
                presentationMode.wrappedValue.dismiss()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("要结束当前的专注时间吗？")
        }
    }
    
    private func startSession() {
        guard !sessionTitle.isEmpty else { return }
        
        timerService.startSession(
            title: sessionTitle,
            tags: selectedTags,
            relatedTask: relatedTask?.id
        )
    }
}

struct StartSessionView: View {
    @Binding var sessionTitle: String
    @Binding var selectedTags: [String]
    @Binding var relatedTask: Task?
    @Binding var showingTaskPicker: Bool
    let onStart: () -> Void
    
    @EnvironmentObject var dataManager: DataManager
    @State private var newTagName = ""
    @State private var showingTagInput = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 专注图标
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // 会话标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专注主题")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("输入专注的主题...", text: $sessionTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 关联任务
                    VStack(alignment: .leading, spacing: 8) {
                        Text("关联任务（可选）")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingTaskPicker = true }) {
                            HStack {
                                if let task = relatedTask {
                                    VStack(alignment: .leading) {
                                        Text(task.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("优先级: \(task.priority.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("选择要关联的任务")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 标签选择
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("标签")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("添加标签") {
                                showingTagInput = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
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
                        
                        if !dataManager.tags.isEmpty {
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
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 开始按钮
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始专注")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sessionTitle.isEmpty ? Color.gray : Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(sessionTitle.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
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
}

struct RunningSessionView: View {
    @EnvironmentObject var timerService: TimerService
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 会话信息
            VStack(spacing: 16) {
                Text(timerService.currentSession?.title ?? "专注中")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let session = timerService.currentSession, !session.tags.isEmpty {
                    HStack {
                        ForEach(session.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // 时间显示
            VStack(spacing: 8) {
                Text(timerService.formattedElapsedTime())
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                
                Text(timerService.sessionState == .running ? "专注中" : "已暂停")
                    .font(.headline)
                    .foregroundColor(timerService.sessionState == .running ? .green : .orange)
            }
            
            // 控制按钮
            HStack(spacing: 30) {
                // 暂停/继续按钮
                Button(action: timerService.isRunning ? onPause : onResume) {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(timerService.isRunning ? Color.orange : Color.green)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // 停止按钮
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TaskPickerView: View {
    @Binding var selectedTask: Task?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    private var incompleteTasks: [Task] {
        dataManager.tasks.filter { !$0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("不关联任务") {
                        selectedTask = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                if !incompleteTasks.isEmpty {
                    Section("选择任务") {
                        ForEach(incompleteTasks) { task in
                            Button(action: {
                                selectedTask = task
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Circle()
                                            .fill(task.priority.color)
                                            .frame(width: 8, height: 8)
                                    }
                                    
                                    if !task.content.isEmpty {
                                        Text(task.content)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    Section {
                        Text("暂无未完成的任务")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择任务")
            .navigationBarItems(
                trailing: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    FocusTimerView()
        .environmentObject(TimerService())
        .environmentObject(DataManager.shared)
}
