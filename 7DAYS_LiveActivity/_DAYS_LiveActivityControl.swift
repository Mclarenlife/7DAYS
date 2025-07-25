//
//  _DAYS_LiveActivityControl.swift
//  7DAYS_LiveActivity
//
//  Created by Mclarenlife on 2025/7/25.
//

import AppIntents
import SwiftUI
import WidgetKit

struct _DAYS_LiveActivityControl: ControlWidget {
    static let kind: String = "com.mclarenlife.7DYAS.FocusTimerControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                value.isRunning ? "暂停专注" : "开始专注",
                isOn: value.isRunning,
                action: ToggleFocusTimerIntent()
            ) { isRunning in
                Label(isRunning ? "专注中" : "开始专注", 
                      systemImage: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .foregroundColor(isRunning ? .orange : .green)
            }
        }
        .displayName("专注计时器")
        .description("控制专注计时器的开始与暂停")
        // 移除不支持的方法
    }
}

extension _DAYS_LiveActivityControl {
    struct Value {
        var isRunning: Bool
        var sessionTitle: String
        var elapsedTime: TimeInterval
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: FocusTimerConfiguration) -> Value {
            _DAYS_LiveActivityControl.Value(
                isRunning: false, 
                sessionTitle: configuration.timerName,
                elapsedTime: 0
            )
        }

        func currentValue(configuration: FocusTimerConfiguration) async throws -> Value {
            // 从UserDefaults或App Group获取当前状态
            let userDefaults = UserDefaults(suiteName: "group.com.mclarenlife.7DYAS")
            let isRunning = userDefaults?.bool(forKey: "focus_timer_running") ?? false
            let sessionTitle = userDefaults?.string(forKey: "focus_session_title") ?? "专注"
            let elapsedTime = userDefaults?.double(forKey: "focus_elapsed_time") ?? 0
            
            return _DAYS_LiveActivityControl.Value(
                isRunning: isRunning, 
                sessionTitle: sessionTitle,
                elapsedTime: elapsedTime
            )
        }
    }
}

struct FocusTimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "专注计时器设置"

    @Parameter(title: "计时器名称", default: "专注")
    var timerName: String
    
    @Parameter(title: "默认时长(分钟)", default: 25)
    var defaultDuration: Int
}

struct ToggleFocusTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "切换专注状态"

    @Parameter(title: "计时器运行状态")
    var value: Bool

    init() {}
    
    // 为在应用中的操作创建URL
    private var appURL: URL? {
        return URL(string: "7dyas://focus/toggle?running=\(value)")
    }

    func perform() async throws -> some IntentResult {
        // 修复在应用扩展中不能使用UIApplication.shared的问题
        // 改为直接返回结果，依赖系统处理URL打开
        return .result(value: value)
    }
}
