//
//  SettingsView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appColorScheme") private var appColorScheme: String = "system" // system, light, dark
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingDataDelete = false
    @State private var showingTagManager = false
    @State private var showingEventManager = false
    @State private var showingWidgetSettings = false
    @State private var showingDynamicIslandSettings = false
    @State private var showingAbout = false
    @State private var showingIconSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // 数据管理
                Section(header: Text("数据")) {
                    Button(action: { showingDataExport = true }) {
                        SettingsRow(icon: "square.and.arrow.up", iconColor: .blue, title: "导出数据")
                    }
                    
                    Button(action: { showingDataImport = true }) {
                        SettingsRow(icon: "square.and.arrow.down", iconColor: .green, title: "导入数据")
                    }
                    
                    Button(action: { showingDataDelete = true }) {
                        SettingsRow(icon: "trash", iconColor: .red, title: "删除数据")
                    }
                }
                
                // 风格设置
                Section(header: Text("风格")) {
                    Picker("外观", selection: $appColorScheme) {
                        Text("跟随系统").tag("system")
                        Text("浅色模式").tag("light")
                        Text("深色模式").tag("dark")
                    }
                    .pickerStyle(.navigationLink)
                    
                    Button(action: { showingIconSettings = true }) {
                        SettingsRow(icon: "app.badge", iconColor: .purple, title: "图标设置")
                    }
                }
                
                // 标签和事项管理
                Section(header: Text("管理")) {
                    Button(action: { showingTagManager = true }) {
                        SettingsRow(icon: "tag", iconColor: .blue, title: "标签管理")
                    }
                    
                    Button(action: { showingEventManager = true }) {
                        SettingsRow(icon: "list.bullet", iconColor: .green, title: "事项管理")
                    }
                }
                
                // 系统集成
                Section(header: Text("系统集成")) {
                    Button(action: { showingWidgetSettings = true }) {
                        SettingsRow(icon: "apps.iphone", iconColor: .orange, title: "小组件")
                    }
                    
                    Button(action: { showingDynamicIslandSettings = true }) {
                        SettingsRow(icon: "capsule.portrait", iconColor: .black, title: "灵动岛")
                    }
                }
                
                // 关于
                Section {
                    Button(action: { showingAbout = true }) {
                        SettingsRow(icon: "info.circle", iconColor: .blue, title: "关于软件")
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .sheet(isPresented: $showingDataImport) {
                DataImportView()
            }
            .sheet(isPresented: $showingDataDelete) {
                DataDeleteView()
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView()
            }
            .sheet(isPresented: $showingEventManager) {
                EventManagerView()
            }
            .sheet(isPresented: $showingWidgetSettings) {
                WidgetSettingsView()
            }
            .sheet(isPresented: $showingDynamicIslandSettings) {
                DynamicIslandSettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingIconSettings) {
                IconSettingsView()
            }
        }
        .onAppear {
            applyColorScheme()
        }
        .onChange(of: appColorScheme) { _, _ in
            applyColorScheme()
        }
    }
    
    private func applyColorScheme() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        switch appColorScheme {
        case "light":
            window?.overrideUserInterfaceStyle = .light
        case "dark":
            window?.overrideUserInterfaceStyle = .dark
        default:
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// 设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 数据导出视图
struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportProgress = 0.0
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isExporting {
                    ProgressView(value: exportProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .padding()
                    
                    Text("正在导出数据...")
                        .font(.headline)
                } else if showingSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()
                    
                    Text("数据导出成功")
                        .font(.headline)
                    
                    Text("文件已保存到您的文件应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("导出应用数据")
                        .font(.headline)
                    
                    Text("导出所有任务、标签、专注记录等数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: startExport) {
                        Text("开始导出")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 40)
                }
            }
            .padding()
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        // 模拟导出过程
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            exportProgress += 0.05
            
            if exportProgress >= 1.0 {
                timer.invalidate()
                isExporting = false
                showingSuccess = true
            }
        }
    }
}

// 数据导入视图
struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding()
                
                Text("导入应用数据")
                    .font(.headline)
                
                Text("从备份文件中恢复所有数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {}) {
                    Text("选择备份文件")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 数据删除视图
struct DataDeleteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingConfirmation = false
    @State private var deleteType: DeleteDataType = .all
    @State private var showingSuccessAlert = false
    @State private var deletedDataType = ""
    
    enum DeleteDataType: String, CaseIterable, Identifiable {
        case all = "所有数据"
        case focus = "专注数据"
        case tasks = "计划数据"
        case checkIns = "打卡数据"
        case temporary = "暂存数据"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all: return "trash"
            case .focus: return "timer"
            case .tasks: return "checklist"
            case .checkIns: return "checkmark.circle"
            case .temporary: return "tray"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .red
            case .focus: return .orange
            case .tasks: return .blue
            case .checkIns: return .green
            case .temporary: return .purple
            }
        }
        
        var description: String {
            switch self {
            case .all: 
                return "将删除所有应用数据，包括任务、标签、专注记录、打卡记录和暂存数据。"
            case .focus: 
                return "将删除所有专注时间记录，包括标题、标签和统计数据。"
            case .tasks: 
                return "将删除所有计划数据，包括任务、标签和相关设置。"
            case .checkIns: 
                return "将删除所有打卡记录和相关统计数据。"
            case .temporary: 
                return "将删除所有暂存的想法和记录。"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding()
                        
                        Text("警告：数据删除后无法恢复")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("请选择要删除的数据类型")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                Section(header: Text("选择要删除的数据")) {
                    ForEach(DeleteDataType.allCases) { type in
                        Button(action: {
                            deleteType = type
                            showingConfirmation = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                    .foregroundColor(type.color)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.rawValue)
                                        .font(.headline)
                                    
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(footer: Text("删除数据前，建议先导出备份")) {
                    EmptyView()
                }
            }
            .navigationTitle("删除数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("确认删除", isPresented: $showingConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteData()
                }
            } message: {
                Text("确定要删除\(deleteType.rawValue)吗？此操作无法撤销。")
            }
            .alert("删除成功", isPresented: $showingSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("\(deletedDataType)已成功删除。")
            }
        }
    }
    
    private func deleteData() {
        // 根据选择的类型执行不同的删除操作
        deletedDataType = deleteType.rawValue
        switch deleteType {
        case .all:
            dataManager.deleteAllData()
        case .focus:
            dataManager.deleteFocusData()
        case .tasks:
            dataManager.deleteTasksData()
        case .checkIns:
            dataManager.deleteCheckInsData()
        case .temporary:
            dataManager.deleteTemporaryData()
        }
        
        // 显示成功提示
        showingSuccessAlert = true
    }
}

// 标签管理视图 - 黑白北欧风格
struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var isCreatingTag = false
    @State private var isCreatingFolder = false
    @State private var newTagName = ""
    @State private var newTagColor: Tag.TagColor = .blue
    @State private var selectedFolderId: UUID? = nil
    @State private var newFolderName = ""
    @State private var expandedFolders = Set<UUID>()
    @State private var isUnclassifiedExpanded = true // 控制无分类标签夹的展开状态
    @State private var isSearching = false // 控制是否处于搜索模式
    @FocusState private var isSearchFieldFocused: Bool // 控制搜索框焦点
    
    // 编辑状态
    @State private var selectedTag: Tag? = nil
    @State private var selectedFolder: TagFolder? = nil
    @State private var showingEditTagSheet = false
    @State private var showingEditFolderSheet = false
    @State private var showingDeleteTagAlert = false
    @State private var showingDeleteFolderAlert = false
    
    // 北欧风格的颜色
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.12) : Color(white: 0.97)
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.17) : Color(white: 0.95)
    }
    private var dividerColor: Color {
        colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.9)
    }
    private var actionColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    if isSearching {
                        // 搜索模式下的搜索栏
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("搜索标签", text: $searchText)
                                    .font(.system(.body, design: .rounded))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .focused($isSearchFieldFocused)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(secondaryBackgroundColor)
                            
                            Rectangle()
                                .fill(dividerColor)
                                .frame(height: 1)
                            
                            // 搜索结果计数
                            HStack {
                                Text("搜索到 \(filteredSearchResults().count) 个标签")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                            .background(secondaryBackgroundColor)
                            
                            // 搜索结果列表
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(filteredSearchResults()) { tag in
                                        NordicTagRow(tag: tag) {
                                            selectedTag = tag
                                            showingEditTagSheet = true
                                        } onDelete: {
                                            selectedTag = tag
                                            showingDeleteTagAlert = true
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .transition(.opacity)
                    } else {
                        // 非搜索模式下的内容
                        ScrollView {
                            VStack(spacing: 24) {
                                // 搜索栏
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isSearching = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isSearchFieldFocused = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                        Text("搜索标签")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(secondaryBackgroundColor)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                                
                                // 创建按钮区域
                                VStack(spacing: 20) {
                                    // 创建标签部分
                                    if isCreatingTag {
                                        // 创建标签表单
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("新标签")
                                                .font(.system(.headline, design: .rounded))
                                            
                                            TextField("标签名称", text: $newTagName)
                                                .font(.system(.body, design: .rounded))
                                                .padding()
                                                .background(secondaryBackgroundColor)
                                                .cornerRadius(8)
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("标签颜色")
                                                    .font(.system(.subheadline, design: .rounded))
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 12) {
                                                        ForEach(Tag.TagColor.allCases, id: \.self) { color in
                                                            Button {
                                                                newTagColor = color
                                                            } label: {
                                                                Circle()
                                                                    .fill(color.swiftUIColor)
                                                                    .frame(width: 24, height: 24)
                                                                    .overlay(
                                                                        Circle()
                                                                            .stroke(newTagColor == color ? Color.white : Color.clear, lineWidth: 2)
                                                                    )
                                                                    .shadow(color: newTagColor == color ? color.swiftUIColor.opacity(0.6) : Color.clear, radius: 4)
                                                            }
                                                        }
                                                    }
                                                    .padding(.vertical, 8)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("选择标签夹")
                                                    .font(.system(.subheadline, design: .rounded))
                                                
                                                Picker("标签夹", selection: $selectedFolderId) {
                                                    Text("无分类").tag(nil as UUID?)
                                                    ForEach(dataManager.tagFolders) { folder in
                                                        Text(folder.name).tag(folder.id as UUID?)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .padding()
                                                .background(secondaryBackgroundColor)
                                                .cornerRadius(8)
                                            }
                                            
                                            HStack {
                                                Button("取消") {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        isCreatingTag = false
                                                        resetNewTagFields()
                                                    }
                                                }
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(secondaryBackgroundColor)
                                                .cornerRadius(8)
                                                
                                                Button("创建") {
                                                    addNewTag()
                                                }
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(actionColor)
                                                .cornerRadius(8)
                                                .disabled(newTagName.isEmpty)
                                                .opacity(newTagName.isEmpty ? 0.5 : 1.0)
                                            }
                                        }
                                        .padding()
                                        .background(cardBackgroundColor)
                                        .cornerRadius(12)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                                            removal: .scale(scale: 0.95).combined(with: .opacity)
                                        ))
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isCreatingTag = true
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "plus.circle")
                                                Text("创建新标签")
                                                    .font(.system(.body, design: .rounded))
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(dividerColor, lineWidth: 1)
                                            )
                                        }
                                    }
                                    
                                    // 创建标签夹部分
                                    if isCreatingFolder {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("新标签夹")
                                                .font(.system(.headline, design: .rounded))
                                            
                                            TextField("标签夹名称", text: $newFolderName)
                                                .font(.system(.body, design: .rounded))
                                                .padding()
                                                .background(secondaryBackgroundColor)
                                                .cornerRadius(8)
                                            
                                            HStack {
                                                Button("取消") {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        isCreatingFolder = false
                                                        newFolderName = ""
                                                    }
                                                }
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(secondaryBackgroundColor)
                                                .cornerRadius(8)
                                                
                                                Button("创建") {
                                                    addNewFolder()
                                                }
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(actionColor)
                                                .cornerRadius(8)
                                                .disabled(newFolderName.isEmpty)
                                                .opacity(newFolderName.isEmpty ? 0.5 : 1.0)
                                            }
                                        }
                                        .padding()
                                        .background(cardBackgroundColor)
                                        .cornerRadius(12)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                                            removal: .scale(scale: 0.95).combined(with: .opacity)
                                        ))
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isCreatingFolder = true
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "folder.badge.plus")
                                                Text("创建新标签夹")
                                                    .font(.system(.body, design: .rounded))
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(dividerColor, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // 标签列表标题
                                Text("全部标签")
                                    .font(.system(.headline, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                // 无分类标签组
                                NordicTagGroup(
                                    title: "无分类",
                                    icon: "tray",
                                    count: filteredUnclassifiedTags().count,
                                    isExpanded: $isUnclassifiedExpanded,
                                    tags: filteredUnclassifiedTags(),
                                    backgroundColor: cardBackgroundColor,
                                    onTagEdit: { tag in
                                        selectedTag = tag
                                        showingEditTagSheet = true
                                    },
                                    onTagDelete: { tag in
                                        selectedTag = tag
                                        showingDeleteTagAlert = true
                                    }
                                )
                                .padding(.horizontal)
                                
                                // 标签夹组
                                ForEach(sortedFolders()) { folder in
                                    NordicTagGroup(
                                        title: folder.name,
                                        icon: "folder",
                                        count: filteredTagsInFolder(folder.id).count,
                                        isExpanded: Binding(
                                            get: { expandedFolders.contains(folder.id) },
                                            set: { isExpanded in
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    if isExpanded {
                                                        expandedFolders.insert(folder.id)
                                                    } else {
                                                        expandedFolders.remove(folder.id)
                                                    }
                                                }
                                            }
                                        ),
                                        tags: filteredTagsInFolder(folder.id),
                                        backgroundColor: cardBackgroundColor,
                                        onFolderEdit: {
                                            selectedFolder = folder
                                            showingEditFolderSheet = true
                                        },
                                        onFolderDelete: {
                                            selectedFolder = folder
                                            showingDeleteFolderAlert = true
                                        },
                                        onTagEdit: { tag in
                                            selectedTag = tag
                                            showingEditTagSheet = true
                                        },
                                        onTagDelete: { tag in
                                            selectedTag = tag
                                            showingDeleteTagAlert = true
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                                
                                // 底部留白
                                Spacer(minLength: 40)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .navigationTitle("标签管理")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if isSearching {
                            Button("取消") {
                                withAnimation {
                                    isSearching = false
                                    searchText = ""
                                    isSearchFieldFocused = false
                                }
                            }
                            .font(.system(.body, design: .rounded))
                        } else {
                            Button("完成") {
                                dismiss()
                            }
                            .font(.system(.body, design: .rounded))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditTagSheet) {
                if let tag = selectedTag {
                    NordicEditTagView(tag: tag)
                }
            }
            .sheet(isPresented: $showingEditFolderSheet) {
                if let folder = selectedFolder {
                    NordicEditFolderView(folder: folder)
                }
            }
            .alert("删除标签", isPresented: $showingDeleteTagAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let tag = selectedTag {
                        dataManager.deleteTag(tag)
                    }
                }
            } message: {
                Text("确定要删除标签\"\(selectedTag?.name ?? "")\"吗？此操作不会删除关联的任务。")
            }
            .alert("删除标签夹", isPresented: $showingDeleteFolderAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let folder = selectedFolder {
                        dataManager.deleteTagFolder(folder)
                    }
                }
            } message: {
                Text("确定要删除标签夹\"\(selectedFolder?.name ?? "")\"吗？标签夹内的标签将被移至\"无分类\"。")
            }
        }
    }
    
    // MARK: - 辅助方法
    
    // 搜索结果
    private func filteredSearchResults() -> [Tag] {
        if searchText.isEmpty {
            return [] // 搜索框为空时返回空数组，不显示任何标签
        } else {
            return dataManager.tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // 获取无分类的标签（并过滤搜索）
    private func filteredUnclassifiedTags() -> [Tag] {
        let unclassified = dataManager.unclassifiedTags()
        if !isSearching || searchText.isEmpty {
            return unclassified
        } else {
            return unclassified.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // 获取指定文件夹中的标签（并过滤搜索）
    private func filteredTagsInFolder(_ folderId: UUID) -> [Tag] {
        let folderTags = dataManager.tagsInFolder(folderId)
        if !isSearching || searchText.isEmpty {
            return folderTags
        } else {
            return folderTags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // 按名称排序的文件夹
    private func sortedFolders() -> [TagFolder] {
        return dataManager.tagFolders.sorted { $0.name < $1.name }
    }
    
    // 切换文件夹展开状态
    private func toggleFolderExpansion(_ folderId: UUID) {
        withAnimation(.easeInOut(duration: 0.35)) {
            if expandedFolders.contains(folderId) {
                expandedFolders.remove(folderId)
            } else {
                expandedFolders.insert(folderId)
            }
        }
    }
    
    // 添加新标签
    private func addNewTag() {
        let newTag = Tag(name: newTagName, color: newTagColor, folderId: selectedFolderId)
        dataManager.addTag(newTag)
        
        withAnimation(.easeInOut(duration: 0.35)) {
            resetNewTagFields()
            isCreatingTag = false
        }
    }
    
    // 添加新文件夹
    private func addNewFolder() {
        let newFolder = TagFolder(name: newFolderName)
        dataManager.addTagFolder(newFolder)
        
        withAnimation(.easeInOut(duration: 0.35)) {
            newFolderName = ""
            isCreatingFolder = false
        }
    }
    
    // 重置新标签的字段
    private func resetNewTagFields() {
        newTagName = ""
        newTagColor = .blue
        selectedFolderId = nil
    }
}

// 北欧风格的标签行
struct NordicTagRow: View {
    let tag: Tag
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            // 左侧布局：标签颜色和名称（垂直居中）
            HStack(spacing: 8) {
                // 标签颜色指示器
                Circle()
                    .fill(tag.color.swiftUIColor)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    // 标签名称
                    Text(tag.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    // 使用次数
                    if tag.usageCount > 0 {
                        Text("已使用: \(tag.usageCount)次")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxHeight: .infinity) // 确保内容在垂直方向上居中
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// 北欧风格的标签组
struct NordicTagGroup: View {
    let title: String
    let icon: String
    let count: Int
    @Binding var isExpanded: Bool
    let tags: [Tag]
    let backgroundColor: Color
    var onFolderEdit: (() -> Void)? = nil
    var onFolderDelete: (() -> Void)? = nil
    let onTagEdit: (Tag) -> Void
    let onTagDelete: (Tag) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // 添加本地状态，用于控制展开/收起动画
    @State private var localExpanded: Bool
    
    init(title: String, icon: String, count: Int, isExpanded: Binding<Bool>, tags: [Tag], backgroundColor: Color, onFolderEdit: (() -> Void)? = nil, onFolderDelete: (() -> Void)? = nil, onTagEdit: @escaping (Tag) -> Void, onTagDelete: @escaping (Tag) -> Void) {
        self.title = title
        self.icon = icon
        self.count = count
        self._isExpanded = isExpanded
        self.tags = tags
        self.backgroundColor = backgroundColor
        self.onFolderEdit = onFolderEdit
        self.onFolderDelete = onFolderDelete
        self.onTagEdit = onTagEdit
        self.onTagDelete = onTagDelete
        // 初始化本地状态 - 如果标签夹为空，则始终为折叠状态
        self._localExpanded = State(initialValue: tags.isEmpty ? false : isExpanded.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            Button(action: {
                // 只有在标签夹不为空时才允许展开
                if !tags.isEmpty {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        localExpanded.toggle()
                        isExpanded.toggle() // 同步到外部状态
                    }
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(icon == "folder" ? .gray : .secondary)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.93))
                        .cornerRadius(12)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        tags.isEmpty 
                            ? (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)) 
                            : (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                        lineWidth: 1
                    )
            )
            .opacity(tags.isEmpty ? 0.8 : 1.0)
            .conditionalContextMenu(show: icon == "folder" && onFolderEdit != nil && onFolderDelete != nil) {
                Button(action: { onFolderEdit?() }) {
                    Label("编辑", systemImage: "pencil")
                }
                Button(role: .destructive, action: { onFolderDelete?() }) {
                    Label("删除", systemImage: "trash")
                }
            }
            // 监听外部状态变化和标签数量变化，同步到本地状态
            .onChange(of: isExpanded) { oldValue, newValue in
                if localExpanded != newValue && !tags.isEmpty {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        localExpanded = newValue
                    }
                }
            }
            .onChange(of: tags.count) { _, newCount in
                // 如果标签夹变空，自动折叠
                if newCount == 0 && localExpanded {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        localExpanded = false
                        isExpanded = false // 同步到外部状态
                    }
                }
            }
            
            // 标签列表（如果展开）
            if localExpanded {
                if !tags.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(tags) { tag in
                            NordicTagRow(tag: tag, onEdit: {
                                onTagEdit(tag)
                            }, onDelete: {
                                onTagDelete(tag)
                            })
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                } else {
                                            Text("无标签")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                }
            }
            
            // 已删除文件夹菜单
        }
    }
}

// 北欧风格的编辑标签视图
struct NordicEditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var dataManager: DataManager
    let tag: Tag
    
    @State private var name: String
    @State private var color: Tag.TagColor
    @State private var folderId: UUID?
    
    // 北欧风格的颜色
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.12) : Color(white: 0.97)
    }
    private var actionColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    init(tag: Tag) {
        self.tag = tag
        _name = State(initialValue: tag.name)
        _color = State(initialValue: tag.color)
        _folderId = State(initialValue: tag.folderId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标签名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标签名称")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            TextField("输入标签名称", text: $name)
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(cardBackgroundColor)
                                .cornerRadius(8)
                        }
                        
                        // 标签颜色选择
                        VStack(alignment: .leading, spacing: 16) {
                            Text("标签颜色")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                                ForEach(Tag.TagColor.allCases, id: \.self) { tagColor in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            color = tagColor
                                        }
                                    } label: {
                                        Circle()
                                            .fill(tagColor.swiftUIColor)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(color == tagColor ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                            .shadow(
                                                color: tagColor.swiftUIColor.opacity(color == tagColor ? 0.5 : 0),
                                                radius: 5
                                            )
                                            .scaleEffect(color == tagColor ? 1.1 : 1.0)
                                    }
                                }
                            }
                            .padding()
                            .background(cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        
                        // 标签夹选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("标签夹")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Picker("选择标签夹", selection: $folderId) {
                                    Text("无分类").tag(nil as UUID?)
                                    ForEach(dataManager.tagFolders) { folder in
                                        Text(folder.name).tag(folder.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            }
                            .background(cardBackgroundColor)
                            .cornerRadius(8)
                        }
                        
                        // 保存按钮
                        Button {
                            saveChanges()
                        } label: {
                            Text("保存")
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(actionColor)
                                .cornerRadius(12)
                                .shadow(color: actionColor.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedTag = tag
        updatedTag.name = name
        updatedTag.color = color
        updatedTag.folderId = folderId
        
        dataManager.updateTag(updatedTag)
        dismiss()
    }
}

// 北欧风格的编辑文件夹视图
struct NordicEditFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var dataManager: DataManager
    let folder: TagFolder
    
    @State private var name: String
    
    // 北欧风格的颜色
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.12) : Color(white: 0.97)
    }
    private var actionColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    init(folder: TagFolder) {
        self.folder = folder
        _name = State(initialValue: folder.name)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // 文件夹图标
                    Image(systemName: "folder.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    
                    // 文件夹名称
                    VStack(alignment: .leading, spacing: 8) {
                        Text("文件夹名称")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField("输入文件夹名称", text: $name)
                            .font(.system(.body, design: .rounded))
                            .padding()
                            .background(cardBackgroundColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // 显示此文件夹中的标签数量
                    let tagCount = dataManager.tagsInFolder(folder.id).count
                    Text("此文件夹包含\(tagCount)个标签")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 保存按钮
                    Button {
                        saveChanges()
                    } label: {
                        Text("保存")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(actionColor)
                            .cornerRadius(12)
                            .shadow(color: actionColor.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("编辑文件夹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedFolder = folder
        updatedFolder.name = name
        
        dataManager.updateTagFolder(updatedFolder)
        dismiss()
    }
}

// 事项管理视图
struct EventManagerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("事项管理视图")
                .navigationTitle("事项管理")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// 小组件设置视图
struct WidgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("小组件显示内容")) {
                    NavigationLink(destination: Text("今日待办设置")) {
                        SettingsRow(icon: "checklist", iconColor: .blue, title: "今日待办")
                    }
                    
                    NavigationLink(destination: Text("专注时间设置")) {
                        SettingsRow(icon: "timer", iconColor: .orange, title: "专注时间")
                    }
                    
                    NavigationLink(destination: Text("统计信息设置")) {
                        SettingsRow(icon: "chart.bar", iconColor: .purple, title: "统计信息")
                    }
                }
                
                Section(header: Text("小组件外观")) {
                    NavigationLink(destination: Text("颜色主题设置")) {
                        SettingsRow(icon: "paintbrush", iconColor: .red, title: "颜色主题")
                    }
                    
                    NavigationLink(destination: Text("字体设置")) {
                        SettingsRow(icon: "textformat", iconColor: .blue, title: "字体")
                    }
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Text("查看小组件使用教程")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("小组件设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 灵动岛设置视图
struct DynamicIslandSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("enableDynamicIsland") private var enableDynamicIsland = true
    @AppStorage("showFocusInDynamicIsland") private var showFocusInDynamicIsland = true
    @AppStorage("showTasksInDynamicIsland") private var showTasksInDynamicIsland = true
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("启用灵动岛", isOn: $enableDynamicIsland)
                }
                
                Section(header: Text("显示内容")) {
                    Toggle("专注时间", isOn: $showFocusInDynamicIsland)
                        .disabled(!enableDynamicIsland)
                    
                    Toggle("待办任务", isOn: $showTasksInDynamicIsland)
                        .disabled(!enableDynamicIsland)
                }
                
                Section(footer: Text("灵动岛功能仅在支持的设备上可用")) {
                    EmptyView()
                }
            }
            .navigationTitle("灵动岛设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 图标设置视图
struct IconSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIcon: String? = nil
    
    let availableIcons = [
        ("默认", nil),
        ("深色", "AppIconDark"),
        ("蓝色", "AppIconBlue"),
        ("红色", "AppIconRed")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableIcons, id: \.0) { name, iconName in
                    Button(action: { setAppIcon(iconName) }) {
                        HStack {
                            Image(iconName ?? "AppIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                            
                            Text(name)
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            if selectedIcon == iconName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("图标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedIcon = UIApplication.shared.alternateIconName
            }
        }
    }
    
    private func setAppIcon(_ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("设置应用图标失败: \(error.localizedDescription)")
            } else {
                selectedIcon = iconName
            }
        }
    }
}

// 关于软件视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 20) {
                        Image("AppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        
                        Text("7天")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                Section(header: Text("开发者")) {
                    Text("Mclarenlife")
                }
                
                Section(header: Text("联系我们")) {
                    Link(destination: URL(string: "mailto:xiangjinleee@gmail.com")!) {
                        HStack {
                            Text("电子邮件")
                            Spacer()
                            Text("xiangjinleee@gmail.com")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com")!) {
                        HStack {
                            Text("官方网站")
                            Spacer()
                            Text("example.com")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: Text("隐私政策内容")) {
                        Text("隐私政策")
                    }
                    
                    NavigationLink(destination: Text("使用条款内容")) {
                        Text("使用条款")
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("© 2025 Mclarenlife. All rights reserved.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 

// 条件上下文菜单的扩展
extension View {
    @ViewBuilder
    func conditionalContextMenu<MenuContent: View>(
        show condition: Bool,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) -> some View {
        if condition {
            self.contextMenu {
                menuContent()
            }
        } else {
            self
        }
    }
} 