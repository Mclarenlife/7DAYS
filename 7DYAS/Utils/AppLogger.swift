//
//  AppLogger.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/22.
//

import Foundation
import UIKit
import os.log

class AppLogger {
    static let shared = AppLogger()
    
    private let osLog = OSLog(subsystem: "com.mclarenlife.7DYAS", category: "app")
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    
    // 日志级别
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        // 创建日志目录
        createLogDirectoryIfNeeded()
        
        // 启动时记录应用启动日志
        log("应用启动", level: .info)
        log("系统版本: \(UIDevice.current.systemVersion)", level: .info)
        log("设备型号: \(UIDevice.current.model)", level: .info)
    }
    
    // MARK: - 日志记录
    
    /// 记录日志
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        // 输出到系统日志
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // 写入文件日志
        writeToLogFile(logMessage)
        
        // 开发环境下同时输出到控制台
        #if DEBUG
        print(logMessage)
        #endif
    }
    
    /// 记录错误
    func logError(_ error: Error, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = "\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)"
        log(errorMessage, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - 文件日志管理
    
    private func createLogDirectoryIfNeeded() {
        guard let logDirectory = getLogDirectory() else { return }
        
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func writeToLogFile(_ message: String) {
        guard let logFile = getCurrentLogFile() else { return }
        
        let logEntry = message + "\n"
        
        if let data = logEntry.data(using: .utf8) {
            if fileManager.fileExists(atPath: logFile.path) {
                // 追加到现有文件
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // 创建新文件
                try? data.write(to: logFile)
            }
        }
        
        // 清理旧日志文件
        cleanOldLogFiles()
    }
    
    private func getCurrentLogFile() -> URL? {
        guard let logDirectory = getLogDirectory() else { return nil }
        
        let today = Date()
        let fileFormatter = DateFormatter()
        fileFormatter.dateFormat = "yyyy-MM-dd"
        fileFormatter.locale = Locale(identifier: "zh_CN")
        
        let fileName = "7DYAS_\(fileFormatter.string(from: today)).log"
        return logDirectory.appendingPathComponent(fileName)
    }
    
    private func getLogDirectory() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("Logs")
    }
    
    private func cleanOldLogFiles() {
        guard let logDirectory = getLogDirectory() else { return }
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            
            for file in logFiles {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: file)
                    log("删除旧日志文件: \(file.lastPathComponent)", level: .info)
                }
            }
        } catch {
            log("清理旧日志文件失败: \(error.localizedDescription)", level: .error)
        }
    }
    
    // MARK: - 日志查看
    
    /// 获取今日日志内容
    func getTodayLogs() -> String? {
        guard let logFile = getCurrentLogFile(),
              fileManager.fileExists(atPath: logFile.path) else {
            return nil
        }
        
        return try? String(contentsOf: logFile, encoding: .utf8)
    }
    
    /// 获取所有日志文件列表
    func getLogFilesList() -> [URL] {
        guard let logDirectory = getLogDirectory() else { return [] }
        
        do {
            return try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "log" }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            log("获取日志文件列表失败: \(error.localizedDescription)", level: .error)
            return []
        }
    }
}
