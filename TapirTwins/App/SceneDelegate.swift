import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // 检查是否有传入的URL
        if let url = connectionOptions.urlContexts.first?.url {
            handleURL(url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleURL(url)
        }
    }
    
    // 处理深度链接
    private func handleURL(_ url: URL) {
        if url.scheme == "tapirtwins" {
            switch url.host {
            case "dreamreminder":
                // 处理打开记录梦境界面
                NotificationCenter.default.post(name: NSNotification.Name("OpenDreamRecording"), object: nil)
                
            case "refreshsignature":
                // 处理刷新签名请求
                refreshCompanionSignature()
                
            default:
                break
            }
        }
    }
    
    // 刷新陪伴模式签名
    private func refreshCompanionSignature() {
        if #available(iOS 16.1, *) {
            let settingsViewModel = SettingsViewModel()
            settingsViewModel.refreshCompanionSignature()
        }
    }
    
    // 添加场景进入前台时的处理
    func sceneWillEnterForeground(_ scene: UIScene) {
        // 当应用进入前台时，检查并恢复灵动岛状态
        if #available(iOS 16.1, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 检查设置并根据需要恢复灵动岛
                let isEnabled = UserDefaults.standard.bool(forKey: "companionModeEnabled")
                if isEnabled {
                    DreamCompanionManager.shared.startCompanionMode()
                    print("应用前台：恢复灵动岛陪伴模式")
                }
            }
        }
    }
} 