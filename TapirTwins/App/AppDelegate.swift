import Foundation
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 检查并恢复灵动岛陪伴模式
        restoreCompanionMode()
        
        return true
    }
    
    // 当应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台也显示通知
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // 用户点击通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // 处理梦境提醒通知
        if identifier == "dreamReminder" {
            // 发送通知通知应用打开梦境记录界面
            NotificationCenter.default.post(name: NSNotification.Name("OpenDreamRecording"), object: nil)
        }
        
        completionHandler()
    }
    
    // 恢复灵动岛陪伴模式
    private func restoreCompanionMode() {
        if #available(iOS 16.1, *) {
            // 延迟执行，确保应用完全启动
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let settingsViewModel = SettingsViewModel()
                
                // 检查是否首次启动但未设置标志位
                let hasSetFlag = UserDefaults.standard.bool(forKey: "hasSavedCompanionModeSetting")
                if !hasSetFlag {
                    // 首次启动，设置为默认开启
                    UserDefaults.standard.set(true, forKey: "companionModeEnabled")
                    UserDefaults.standard.set(true, forKey: "hasSavedCompanionModeSetting")
                }
                
                // 无论如何都会检查和恢复
                settingsViewModel.checkAndRestoreCompanionMode()
            }
        }
    }
} 