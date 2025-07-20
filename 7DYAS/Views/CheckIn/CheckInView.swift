//
//  CheckInView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewCheckIn = false
    
    private var activeCheckIns: [CheckIn] {
        dataManager.getActiveCheckIns()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 简化的顶部导航
            CheckInHeader(onNewCheckIn: { showingNewCheckIn = true })
            
            if activeCheckIns.isEmpty {
                EmptyCheckInView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(activeCheckIns) { checkIn in
                            CheckInCard(checkIn: checkIn)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .sheet(isPresented: $showingNewCheckIn) {
            NewCheckInView()
        }
    }
}

struct CheckInHeader: View {
    let onNewCheckIn: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("培养好习惯，坚持每一天")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onNewCheckIn) {
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

struct EmptyCheckInView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("还没有打卡项目")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("创建一个打卡项目开始培养好习惯")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct CheckInCard: View {
    let checkIn: CheckIn
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(spacing: 16) {
                // 顶部信息
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: checkIn.category.icon)
                            .font(.title2)
                            .foregroundColor(checkIn.category.color)
                            .frame(width: 40, height: 40)
                            .background(checkIn.category.color.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(checkIn.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(checkIn.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 打卡按钮
                    CheckInButton(checkIn: checkIn)
                }
                
                // 进度条
                CheckInProgressView(checkIn: checkIn)
                
                // 统计信息
                HStack {
                    StatItem(
                        title: "连续",
                        value: "\(checkIn.currentStreak)天",
                        color: .orange
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "总计",
                        value: "\(checkIn.totalDays)天",
                        color: .blue
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "完成率",
                        value: String(format: "%.0f%%", checkIn.completionRate * 100),
                        color: .green
                    )
                }
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            CheckInDetailView(checkIn: checkIn)
        }
    }
}

struct CheckInButton: View {
    let checkIn: CheckIn
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Button(action: toggleCheckIn) {
            Image(systemName: checkIn.hasCheckedInToday ? "checkmark.circle.fill" : "circle")
                .font(.title)
                .foregroundColor(checkIn.hasCheckedInToday ? .green : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleCheckIn() {
        if checkIn.hasCheckedInToday {
            dataManager.undoCheckIn(for: checkIn)
        } else {
            dataManager.performCheckIn(for: checkIn)
        }
    }
}

struct CheckInProgressView: View {
    let checkIn: CheckIn
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("目标进度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(checkIn.totalDays)/\(checkIn.targetDays)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: checkIn.completionRate)
                .progressViewStyle(LinearProgressViewStyle(tint: checkIn.category.color))
                .scaleEffect(x: 1, y: 2)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// 新建打卡视图（简化版）
struct NewCheckInView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetDays = 30
    @State private var selectedCategory: CheckIn.CheckInCategory = .habit
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("打卡名称", text: $title)
                    TextField("描述（可选）", text: $description)
                }
                
                Section(header: Text("目标设置")) {
                    Stepper("目标天数: \(targetDays)", value: $targetDays, in: 1...365)
                }
                
                Section(header: Text("分类")) {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(CheckIn.CheckInCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("新建打卡")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveCheckIn()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveCheckIn() {
        let checkIn = CheckIn(
            title: title,
            description: description,
            targetDays: targetDays,
            category: selectedCategory
        )
        
        dataManager.addCheckIn(checkIn)
        presentationMode.wrappedValue.dismiss()
    }
}

// 打卡详情视图（简化版）
struct CheckInDetailView: View {
    let checkIn: CheckIn
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("打卡详情页面")
                        .font(.title)
                    Text("功能开发中...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("打卡详情")
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    CheckInView()
        .environmentObject(DataManager.shared)
}
