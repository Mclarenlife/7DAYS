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

// 标签管理视图
struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var tags: [Tag] = []
    @State private var newTagName = ""
    @State private var editingTag: Tag? = nil
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: Tag? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("添加标签")) {
                    HStack {
                        TextField("新标签名称", text: $newTagName)
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newTagName.isEmpty)
                    }
                }
                
                Section(header: Text("已有标签")) {
                    if tags.isEmpty {
                        Text("暂无标签")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(tags) { tag in
                            HStack {
                                Text(tag.name)
                                
                                Spacer()
                                
                                Button(action: { editTag(tag) }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                                
                                Button(action: { confirmDelete(tag) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("编辑标签", isPresented: .constant(editingTag != nil)) {
                if let tag = editingTag {
                    TextField("标签名称", text: .constant(tag.name))
                    Button("取消") {
                        editingTag = nil
                    }
                    Button("保存") {
                        // 保存编辑后的标签
                        editingTag = nil
                    }
                }
            }
            .alert("删除标签", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let tag = tagToDelete {
                        deleteTag(tag)
                    }
                }
            } message: {
                Text("确定要删除此标签吗？此操作不会删除关联的任务。")
            }
            .onAppear {
                loadTags()
            }
        }
    }
    
    private func loadTags() {
        tags = dataManager.tags
    }
    
    private func addTag() {
        guard !newTagName.isEmpty else { return }
        
        let newTag = Tag(name: newTagName)
        dataManager.addTag(newTag)
        newTagName = ""
        loadTags()
    }
    
    private func editTag(_ tag: Tag) {
        editingTag = tag
    }
    
    private func confirmDelete(_ tag: Tag) {
        tagToDelete = tag
        showingDeleteAlert = true
    }
    
    private func deleteTag(_ tag: Tag) {
        dataManager.deleteTag(tag)
        loadTags()
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
                        
                        Text("7天助手")
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
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        HStack {
                            Text("电子邮件")
                            Spacer()
                            Text("support@example.com")
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