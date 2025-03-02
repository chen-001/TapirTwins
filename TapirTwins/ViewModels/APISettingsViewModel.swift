import Foundation
import SwiftUI

class APISettingsViewModel: ObservableObject {
    @Published var apiURL: String = APIConfig.baseURL
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isSuccess = false
    
    // 加载当前设置
    func loadSettings() {
        apiURL = APIConfig.baseURL
    }
    
    // 保存API设置
    func saveAPISettings() -> Bool {
        // 验证URL格式
        guard let url = URL(string: apiURL), UIApplication.shared.canOpenURL(url) else {
            alertMessage = "请输入有效的URL地址"
            isSuccess = false
            showingAlert = true
            return false
        }
        
        // 确保URL以"http://"或"https://"开头
        if !apiURL.hasPrefix("http://") && !apiURL.hasPrefix("https://") {
            alertMessage = "URL必须以http://或https://开头"
            isSuccess = false
            showingAlert = true
            return false
        }
        
        // 保存设置
        let oldURL = APIConfig.baseURL
        APIConfig.baseURL = apiURL
        
        // 如果URL发生变化，需要登出用户
        if oldURL != apiURL {
            AuthService.shared.logout()
            alertMessage = "API服务器地址已更新，您已被登出，请重新登录。"
        } else {
            alertMessage = "API服务器地址已保存。"
        }
        
        isSuccess = true
        showingAlert = true
        return true
    }
    
    // 重置为默认设置
    func resetToDefault() {
        let oldURL = APIConfig.baseURL
        APIConfig.resetToDefaultURL()
        apiURL = APIConfig.baseURL
        
        // 如果URL发生变化，需要登出用户
        if oldURL != apiURL {
            AuthService.shared.logout()
            alertMessage = "API服务器地址已重置为默认值，您已被登出，请重新登录。"
        } else {
            alertMessage = "API服务器地址已重置为默认值。"
        }
        
        isSuccess = true
        showingAlert = true
    }
}
