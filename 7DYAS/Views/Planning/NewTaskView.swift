//
//  NewTaskView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct NewTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: PlanningViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedPriority: Task.TaskPriority = .low
    @State private var selectedTags: [String] = []
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var newTagName = ""
    @State private var showingTagInput = false
    @State private var selectedType: TaskType = .plan
    @State private var selectedCycle: TaskCycle = .day
    @State private var selectedDateRange: TaskDateRange? = nil
    @State private var atItems: [String] = []
    @State private var newAtItem = ""
    @State private var createdDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                typeAndCycleSection
                
                // 标题部分独立成一个Section
                Section(header: Text("标题")) {
                    titleSection
                }
                
                // 描述部分独立成一个Section
                Section(header: Text("描述")) {
                    descriptionSection
                }
                
                Section(header: Text("优先级")) {
                    prioritySection
                }
                Section(header: Text("截止日期")) {
                    dueDateSection
                }
                Section(header: Text("标签")) {
                    tagSection
                }
                if !viewModel.tags.isEmpty {
                    Section(header: Text("选择已有标签")) {
                        existingTagsSection
                    }
                }
                Section(header: Text("@事项")) {
                    atItemsSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("新建计划")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .alert("添加标签", isPresented: $showingTagInput) {
            TextField("标签名称", text: $newTagName)
            Button("添加") {
                if !newTagName.isEmpty && !selectedTags.contains(newTagName) {
                    selectedTags.append(newTagName)
                    
                    // 添加到全局标签列表
                    let newTag = Tag(name: newTagName)
                    viewModel.addTag(newTag)
                    
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
            priority: selectedPriority,
            type: selectedType,
            cycle: selectedCycle,
            dateRange: selectedDateRange,
            atItems: atItems,
            images: [],
            createdDate: createdDate
        )
        
        viewModel.addTask(task)
        
        // 增加标签使用次数
        for tagName in selectedTags {
            viewModel.incrementTagUsage(tagName)
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

// 新增日期范围选择器
struct DateRangePicker: View {
    let cycle: TaskCycle
    @Binding var selected: TaskDateRange?
    @State private var weekDays = [1,2,3,4,5,6,7] // 周一到周日
    @State private var monthPeriods = [1,2,3] // 上中下旬
    @State private var yearMonths = Array(1...12)
    var body: some View {
        switch cycle {
        case .day:
            EmptyView()
        case .week:
            VStack(alignment: .leading, spacing: 8) {
                Text("选择周几：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weekDays, id: \.self) { day in
                            Button(action: {
                                toggle(day)
                            }) {
                                Text(["一","二","三","四","五","六","日"][day-1])
                                    .font(.body)
                                    .frame(width: 40, height: 40)
                                    .background(selected?.selectedDays.contains(day) == true ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selected?.selectedDays.contains(day) == true ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        case .month:
            VStack(alignment: .leading, spacing: 8) {
                Text("选择区间：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    ForEach(monthPeriods, id: \.self) { period in
                        Button(action: { toggle(period) }) {
                            Text(["上旬","中旬","下旬"][period-1])
                                .font(.body)
                                .frame(width: 60, height: 36)
                                .background(selected?.selectedDays.contains(period) == true ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selected?.selectedDays.contains(period) == true ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            }
        case .year:
            VStack(alignment: .leading, spacing: 8) {
                Text("选择月份：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(yearMonths, id: \.self) { m in
                            Button(action: { toggle(m) }) {
                                Text("\(m)月")
                                    .font(.body)
                                    .frame(width: 48, height: 36)
                                    .background(selected?.selectedDays.contains(m) == true ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selected?.selectedDays.contains(m) == true ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    private func toggle(_ v: Int) {
        if selected == nil { selected = TaskDateRange(cycle: cycle, selectedDays: [v]); return }
        if selected!.selectedDays.contains(v) {
            selected!.selectedDays.removeAll { $0 == v }
        } else {
            selected!.selectedDays.append(v)
        }
    }
}

// 拆分Section内容为小View
extension NewTaskView {
    private var typeAndCycleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("创建时间")
                    .font(.headline)
                Spacer()
                DatePicker("", selection: $createdDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .frame(maxWidth: 220)
            }
            HStack {
                Text("周期")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedCycle) {
                    ForEach(TaskCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 120)
            }
            if selectedCycle == .day {
                HStack {
                    Text("类型")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $selectedType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 120)
                }
            }
            DateRangePicker(cycle: selectedCycle, selected: $selectedDateRange)
        }
        .padding(.vertical, 4)
    }
    
    private var titleSection: some View {
        TextField("计划标题", text: $title)
            .font(.body)
            .padding(.vertical, 4)
    }
    
    private var descriptionSection: some View {
        TextEditor(text: $content)
            .frame(minHeight: 100)
            .padding(.vertical, 4)
    }
    
    private var prioritySection: some View {
        Picker("优先级", selection: $selectedPriority) {
            ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
                HStack {
                    Circle().fill(priority.color).frame(width: 12, height: 12)
                    Text(priority.rawValue)
                }.tag(priority)
            }
        }.pickerStyle(SegmentedPickerStyle())
    }
    
    private var dueDateSection: some View {
        VStack {
            Toggle("设置截止日期", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("截止日期", selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }), displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
    
    private var tagSection: some View {
        VStack {
            if !selectedTags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagView(tag: tag, isSelected: true) {
                            selectedTags.removeAll { $0 == tag }
                        }
                    }
                }
            }
            Button("添加标签") { showingTagInput = true }
        }
    }
    
    private var existingTagsSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(viewModel.tags, id: \.id) { tag in
                TagView(tag: tag.name, isSelected: selectedTags.contains(tag.name)) {
                    if selectedTags.contains(tag.name) {
                        selectedTags.removeAll { $0 == tag.name }
                    } else {
                        selectedTags.append(tag.name)
                    }
                }
            }
        }
    }
    
    private var atItemsSection: some View {
        VStack {
            HStack {
                TextField("添加@事项", text: $newAtItem)
                Button("添加") {
                    if !newAtItem.isEmpty {
                        atItems.append(newAtItem)
                        newAtItem = ""
                    }
                }
            }
            if !atItems.isEmpty {
                HStack {
                    ForEach(atItems, id: \.self) { at in
                        Text("@" + at)
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 4)
                            .background(Color.purple.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

#Preview {
    NewTaskView()
        .environmentObject(DataManager.shared)
}
