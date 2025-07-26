//
//  SceneDelegate.swift
//  7DYAS
//
//  Created by Mclarenlife on 2025/7/21.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        // 创建 SwiftUI 视图
        let contentView = ContentView()

        // 使用 UIHostingController 将 SwiftUI 视图包装到 UIKit 中
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // 处理启动时的URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingURL(urlContext.url)
        }
    }
    
    // 处理应用在前台时收到的URL
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            handleIncomingURL(urlContext.url)
        }
    }

    // URL处理函数
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "7dyas" else { return }
        
        // 根据URL路径分发不同的操作
        if url.host == "focus" && url.path == "/toggle" {
            // 切换专注状态
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            let shouldRun = components?.queryItems?.first(where: { $0.name == "running" })?.value == "true"
            
            // 使用TimerService单例并执行操作
            DispatchQueue.main.async {
                let timerService = TimerService.shared
                
                if shouldRun {
                    // 如果当前没有会话，创建默认会话
                    if timerService.sessionState == .idle {
                        timerService.startSession(title: "快速专注", tags: ["小组件启动"])
                    } else if timerService.sessionState == .paused {
                        // 如果已暂停，则恢复
                        timerService.resumeSession()
                    }
                } else {
                    // 如果正在运行，则暂停
                    if timerService.sessionState == .running {
                        timerService.pauseSession()
                    }
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 当应用程序变为活动状态时调用
        // 例如，当应用程序从后台恢复或首次启动时
        
        // 检查今天是否已经顺延过任务
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = ISO8601DateFormatter().string(from: today)
        let lastDeferDate = defaults.string(forKey: "LastTaskDeferDate")
        
        // 如果今天还没有顺延过任务，则执行顺延
        if lastDeferDate != todayString {
            // 将前一天未完成的任务顺延到今天
            DataManager.shared.deferUncompletedTasksToToday()
            
            // 记录今天已经顺延过任务
            defaults.set(todayString, forKey: "LastTaskDeferDate")
        }
        
        // 如果TimerService正在运行，确保计时器正常工作
        let timerService = TimerService.shared
        if timerService.isRunning && timerService.timer == nil {
            timerService.startTimer()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // 确保TimerService在后台继续运行
        let timerService = TimerService.shared
        if timerService.isRunning {
            // 强制更新一次实时活动，确保状态正确
            timerService.updateLiveActivity()
        }
    }
}

