//
//  TapirTwinsApp.swift
//  TapirTwins
//
//  Created by 陈宗伟 on 2025/2/28.
//

import SwiftUI
import UserNotifications
import ActivityKit

@main
struct TapirTwinsApp: App {
    // 注册AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 环境对象，用于处理通知导航
    @StateObject private var notificationHandler = NotificationHandler()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(notificationHandler)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenDreamRecording"))) { _ in
                        // 收到通知后，设置标志以打开梦境记录界面
                        notificationHandler.shouldOpenDreamRecording = true
                    }
                    .onOpenURL { url in
                        // 处理从灵动岛点击进入的URL
                        handleDeepLink(url: url)
                    }
                
                // 添加通知横幅到顶层
                NotificationBannerView()
            }
        }
    }
    
    // 处理深度链接
    private func handleDeepLink(url: URL) {
        print("收到深度链接: \(url.absoluteString)")
        
        if url.scheme == "tapirtwins" {
            if url.host == "dreamreminder" {
                // 从灵动岛进入 - 打开梦境记录界面
                notificationHandler.shouldOpenDreamRecording = true
                
                // 如果有活动的灵动岛，可以更新其状态
                if #available(iOS 16.1, *) {
                    if !Activity<DreamReminderAttributes>.activities.isEmpty {
                        // 更新灵动岛显示
                        DreamReminderActivityManager.shared.updateActivity(message: "正在记录梦境...")
                    }
                }
            }
        }
    }
}

// 通知处理器，用于处理打开特定界面的逻辑
class NotificationHandler: ObservableObject {
    @Published var shouldOpenDreamRecording: Bool = false
}
