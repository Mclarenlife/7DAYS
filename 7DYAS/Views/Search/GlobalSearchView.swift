//
//  GlobalSearchView.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import SwiftUI

struct GlobalSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all
    
    enum SearchScope: String, CaseIterable {
        case all = "全部"
        case tasks = "任务"
        case ideas = "想法"
        case checkIns = "打卡"
        case focusSessions = "专注"
        
        var icon: String {
            switch self {
            case .all: return "doc.text.magnifyingglass"
            case .tasks: return "list.bullet"
            case .ideas: return "lightbulb"
            case .checkIns: return "checkmark.circle"
            case .focusSessions: return "timer"
            }
        }
    }
    
    var searchResults: [SearchResult] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let query = searchText.lowercased()
        var results: [SearchResult] = []
        
        // 搜索任务
        if selectedScope == .all || selectedScope == .tasks {
            let taskResults = dataManager.tasks.compactMap { task -> SearchResult? in
                if task.title.lowercased().contains(query) ||
                   task.content.lowercased().contains(query) ||
                   task.tags.joined().lowercased().contains(query) {
                    return SearchResult(type: .task, item: task, matchedText: getMatchedText(task))
                }
                return nil
            }
            results.append(contentsOf: taskResults)
        }
        
        // 搜索想法
        if selectedScope == .all || selectedScope == .ideas {
            let ideaResults = dataManager.temporaryIdeas.compactMap { idea -> SearchResult? in
                if idea.content.lowercased().contains(query) ||
                   idea.tags.joined().lowercased().contains(query) {
                    return SearchResult(type: .idea, item: idea, matchedText: getMatchedText(idea))
                }
                return nil
            }
            results.append(contentsOf: ideaResults)
        }
        
        // 搜索打卡
        if selectedScope == .all || selectedScope == .checkIns {
            let checkInResults = dataManager.checkIns.compactMap { checkIn -> SearchResult? in
                if checkIn.title.lowercased().contains(query) ||
                   checkIn.description.lowercased().contains(query) {
                    return SearchResult(type: .checkIn, item: checkIn, matchedText: getMatchedText(checkIn))
                }
                return nil
            }
            results.append(contentsOf: checkInResults)
        }
        
        // 搜索专注会话
        if selectedScope == .all || selectedScope == .focusSessions {
            let sessionResults = dataManager.focusSessions.compactMap { session -> SearchResult? in
                if session.title.lowercased().contains(query) ||
                   session.notes.lowercased().contains(query) ||
                   session.tags.joined().lowercased().contains(query) {
                    return SearchResult(type: .focusSession, item: session, matchedText: getMatchedText(session))
                }
                return nil
            }
            results.append(contentsOf: sessionResults)
        }
        
        return results.sorted { result1, result2 in
            // 按类型和创建时间排序
            if result1.type != result2.type {
                return result1.type.rawValue < result2.type.rawValue
            }
            return result1.createdDate > result2.createdDate
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(searchText: $searchText)
                
                // 范围选择器
                ScopeSelector(selectedScope: $selectedScope)
                
                // 搜索结果
                SearchResultsList(results: searchResults, searchText: searchText)
            }
            .navigationTitle("全局搜索")
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func getMatchedText(_ item: Any) -> String {
        let query = searchText.lowercased()
        
        if let task = item as? TodoTask {
            if task.title.lowercased().contains(query) {
                return task.title
            } else if task.content.lowercased().contains(query) {
                return String(task.content.prefix(100))
            }
        } else if let idea = item as? TemporaryIdea {
            return String(idea.content.prefix(100))
        } else if let checkIn = item as? CheckIn {
            if checkIn.title.lowercased().contains(query) {
                return checkIn.title
            } else {
                return checkIn.description
            }
        } else if let session = item as? FocusSession {
            if session.title.lowercased().contains(query) {
                return session.title
            } else {
                return session.notes
            }
        }
        
        return ""
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let item: Any
    let matchedText: String
    
    var createdDate: Date {
        if let task = item as? TodoTask {
            return task.createdDate
        } else if let idea = item as? TemporaryIdea {
            return idea.createdDate
        } else if let checkIn = item as? CheckIn {
            return checkIn.createdDate
        } else if let session = item as? FocusSession {
            return session.startTime
        }
        return Date()
    }
}

enum SearchResultType: String, CaseIterable {
    case task = "任务"
    case idea = "想法"
    case checkIn = "打卡"
    case focusSession = "专注"
    
    var icon: String {
        switch self {
        case .task: return "list.bullet"
        case .idea: return "lightbulb"
        case .checkIn: return "checkmark.circle"
        case .focusSession: return "timer"
        }
    }
    
    var color: Color {
        switch self {
        case .task: return .blue
        case .idea: return .purple
        case .checkIn: return .green
        case .focusSession: return .orange
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索任务、想法、打卡...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct ScopeSelector: View {
    @Binding var selectedScope: GlobalSearchView.SearchScope
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GlobalSearchView.SearchScope.allCases, id: \.self) { scope in
                    Button(action: { selectedScope = scope }) {
                        HStack(spacing: 6) {
                            Image(systemName: scope.icon)
                                .font(.caption)
                            Text(scope.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedScope == scope ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedScope == scope ? Color.blue : Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
    }
}

struct SearchResultsList: View {
    let results: [SearchResult]
    let searchText: String
    
    var body: some View {
        if results.isEmpty {
            if searchText.isEmpty {
                SearchEmptyView(message: "输入关键词开始搜索")
            } else {
                SearchEmptyView(message: "未找到相关结果")
            }
        } else {
            List {
                ForEach(results) { result in
                    SearchResultRow(result: result, searchText: searchText)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct SearchEmptyView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let searchText: String
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.type.icon)
                    .font(.caption)
                    .foregroundColor(result.type.color)
                    .frame(width: 16)
                
                Text(result.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(result.type.color)
                
                Spacer()
                
                Text(dateFormatter.string(from: result.createdDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(highlightedText(result.matchedText, query: searchText))
                .font(.subheadline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
    
    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = text.range(of: query, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            if let attributedRange = Range(nsRange, in: attributedString) {
                attributedString[attributedRange].foregroundColor = .blue
                attributedString[attributedRange].font = .subheadline.bold()
            }
        }
        
        return attributedString
    }
}

#Preview {
    GlobalSearchView()
        .environmentObject(DataManager.shared)
}
