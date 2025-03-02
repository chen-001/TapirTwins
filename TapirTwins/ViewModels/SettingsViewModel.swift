import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var defaultShareSpaceId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        // 从本地加载设置
        let settings = UserSettings.load()
        self.defaultShareSpaceId = settings.defaultShareSpaceId
    }
    
    func fetchSettings() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchUserSettings { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let settings):
                    self?.defaultShareSpaceId = settings.defaultShareSpaceId
                    
                    // 更新本地存储
                    var userSettings = UserSettings.load()
                    userSettings.defaultShareSpaceId = settings.defaultShareSpaceId
                    userSettings.save()
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    func updateDefaultShareSpace(spaceId: String?) {
        isLoading = true
        errorMessage = nil
        
        let settings = UserSettingsRequest(defaultShareSpaceId: spaceId)
        
        apiService.updateUserSettings(settings: settings) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.defaultShareSpaceId = response.defaultShareSpaceId
                    
                    // 更新本地存储
                    var userSettings = UserSettings.load()
                    userSettings.defaultShareSpaceId = response.defaultShareSpaceId
                    userSettings.save()
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: APIError) {
        switch error {
        case .serverError(let message):
            errorMessage = message
        case .requestFailed(let error):
            errorMessage = "请求失败: \(error.localizedDescription)"
        case .decodingFailed:
            errorMessage = "数据解析失败"
        case .invalidURL:
            errorMessage = "无效的URL"
        case .invalidResponse:
            errorMessage = "服务器响应无效"
        case .unknown:
            errorMessage = "发生未知错误"
        case .unauthorized:
            errorMessage = "未授权，请重新登录"
        case .noData:
            errorMessage = "服务器未返回数据"
        }
    }
} 