//
//  TimeValidator.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/22.
//

import Foundation

/// 时间校验工具类
struct TimeValidator {
    
    /// 校验日志文件中的时间格式
    /// - Parameter content: 日志文件内容
    /// - Returns: 校验结果和错误信息
    static func validateChangelogTimes(content: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        // 匹配时间格式的正则表达式
        let timePattern = #"#### (\d{4})年(\d{1,2})月(\d{1,2})日 (\d{1,2}):(\d{2})"#
        let regex = try! NSRegularExpression(pattern: timePattern)
        
        var previousTime: Date?
        let dateFormatter = createDateFormatter()
        
        for (lineNumber, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if let match = regex.firstMatch(in: line, range: range) {
                let year = Int(String(line[Range(match.range(at: 1), in: line)!]))!
                let month = Int(String(line[Range(match.range(at: 2), in: line)!]))!
                let day = Int(String(line[Range(match.range(at: 3), in: line)!]))!
                let hour = Int(String(line[Range(match.range(at: 4), in: line)!]))!
                let minute = Int(String(line[Range(match.range(at: 5), in: line)!]))!
                
                // 验证日期有效性
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day
                components.hour = hour
                components.minute = minute
                
                guard let currentTime = Calendar.current.date(from: components) else {
                    errors.append("第\(lineNumber + 1)行: 无效的日期时间 - \(line)")
                    continue
                }
                
                // 验证时间顺序（应该是倒序，新的在前）
                if let prevTime = previousTime, currentTime > prevTime {
                    errors.append("第\(lineNumber + 1)行: 时间顺序错误，应该按照时间倒序排列")
                }
                
                // 验证时间是否在合理范围内
                let now = Date()
                if currentTime > now {
                    errors.append("第\(lineNumber + 1)行: 时间不能超过当前时间")
                }
                
                let earliestDate = dateFormatter.date(from: "2025年1月1日 00:00")!
                if currentTime < earliestDate {
                    errors.append("第\(lineNumber + 1)行: 时间过早，不在合理范围内")
                }
                
                previousTime = currentTime
            }
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// 获取当前时间的格式化字符串
    /// - Returns: 格式化的当前时间字符串
    static func getCurrentTimeString() -> String {
        let formatter = createDateFormatter()
        return formatter.string(from: Date())
    }
    
    /// 创建标准的日期格式化器
    /// - Returns: 配置好的DateFormatter
    private static func createDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    /// 验证版本号格式
    /// - Parameter version: 版本号字符串
    /// - Returns: 是否为有效的语义化版本号
    static func validateVersionNumber(_ version: String) -> Bool {
        let versionPattern = #"^\[(\d+)\.(\d+)\.(\d+)\]$"#
        let regex = try! NSRegularExpression(pattern: versionPattern)
        let range = NSRange(location: 0, length: version.utf16.count)
        return regex.firstMatch(in: version, range: range) != nil
    }
    
    /// 自动生成下一个版本号
    /// - Parameter currentVersion: 当前版本号 (如 "1.1.0")
    /// - Parameter changeType: 变更类型 (major, minor, patch)
    /// - Returns: 下一个版本号
    static func generateNextVersion(_ currentVersion: String, changeType: VersionChangeType) -> String {
        let components = currentVersion.components(separatedBy: ".")
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]) else {
            return "1.0.0"
        }
        
        switch changeType {
        case .major:
            return "\(major + 1).0.0"
        case .minor:
            return "\(major).\(minor + 1).0"
        case .patch:
            return "\(major).\(minor).\(patch + 1)"
        }
    }
}

/// 版本变更类型
enum VersionChangeType {
    case major  // 主版本号：不兼容的 API 修改
    case minor  // 次版本号：向下兼容的功能性新增
    case patch  // 修订版本号：向下兼容的问题修正
}

/// 日志条目类型
enum LogEntryType: String, CaseIterable {
    case added = "✨ **新增功能**"
    case changed = "🔧 **功能改进**"
    case fixed = "🐛 **Bug修复**"
    case removed = "❌ **移除功能**"
    case security = "🔒 **安全更新**"
    case deprecated = "⚠️ **弃用警告**"
}

/// 日志工具扩展
extension TimeValidator {
    
    /// 生成新的日志条目
    /// - Parameters:
    ///   - type: 条目类型
    ///   - title: 功能标题
    ///   - description: 功能描述
    ///   - time: 时间（可选，默认当前时间）
    /// - Returns: 格式化的日志条目
    static func generateLogEntry(
        type: LogEntryType,
        title: String,
        description: String,
        time: Date = Date()
    ) -> String {
        let timeString = createDateFormatter().string(from: time)
        return """
        #### \(timeString) - \(title)
        \(description)
        """
    }
    
    /// 检查日志结构完整性
    /// - Parameter content: 日志内容
    /// - Returns: 结构检查结果
    static func validateLogStructure(content: String) -> (isValid: Bool, suggestions: [String]) {
        var suggestions: [String] = []
        
        // 检查是否包含必要的版本头
        if !content.contains("## [") {
            suggestions.append("缺少版本号标题，应使用 ## [x.x.x] - YYYY年M月D日 格式")
        }
        
        // 检查是否有分类标题
        let hasCategories = LogEntryType.allCases.contains { type in
            content.contains(type.rawValue)
        }
        
        if !hasCategories {
            suggestions.append("建议添加功能分类标题，如：✨ 新增功能、🔧 功能改进等")
        }
        
        // 检查时间格式一致性
        let timePattern = #"#### \d{4}年\d{1,2}月\d{1,2}日 \d{1,2}:\d{2}"#
        let regex = try! NSRegularExpression(pattern: timePattern)
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: content.utf16.count))
        
        if matches.isEmpty {
            suggestions.append("建议为功能条目添加时间标记")
        }
        
        return (suggestions.isEmpty, suggestions)
    }
}
