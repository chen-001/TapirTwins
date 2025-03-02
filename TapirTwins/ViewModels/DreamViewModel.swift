import Foundation
import SwiftUI

class DreamViewModel: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private let apiService = APIService.shared
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreams
        } else {
            return dreams.filter { dream in
                let searchQuery = searchText.lowercased()
                return dream.title.lowercased().contains(searchQuery) ||
                       dream.content.lowercased().contains(searchQuery) ||
                       dream.date.contains(searchQuery)
            }
        }
    }
    
    func fetchDreams() {
        isLoading = true
        errorMessage = nil
        
        // 先获取个人梦境
        apiService.fetchDreams { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let personalDreams):
                    self.dreams = personalDreams
                    
                    // 检查是否有默认空间，如果有，则获取该空间的梦境
                    let settings = UserSettings.load()
                    if let defaultSpaceId = settings.defaultShareSpaceId {
                        self.fetchSpaceDreamsAndMerge(spaceId: defaultSpaceId)
                    } else {
                        // 没有默认空间，所以只显示个人梦境
                        self.dreams.sort(by: { $0.date > $1.date })
                        self.isLoading = false
                    }
                    
                case .failure(let error):
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchSpaceDreamsAndMerge(spaceId: String) {
        apiService.fetchSpaceDreams(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let spaceDreams):
                    // 将空间梦境添加到dreams数组，但需要避免重复
                    var uniqueDreams = self.dreams
                    
                    // 遍历空间梦境，只添加不重复的梦境
                    for spaceDream in spaceDreams {
                        // 检查是否已经存在相同内容的梦境（比较标题和日期）
                        let isDuplicate = uniqueDreams.contains { existingDream in
                            // 认为标题相同且日期相同的梦境是重复的
                            return existingDream.title == spaceDream.title && 
                                   existingDream.date == spaceDream.date
                        }
                        
                        // 如果不是重复的，则添加到列表
                        if !isDuplicate {
                            uniqueDreams.append(spaceDream)
                        }
                    }
                    
                    // 按日期排序
                    self.dreams = uniqueDreams.sorted(by: { $0.date > $1.date })
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func addDream(title: String, content: String, date: String, completion: @escaping (Bool) -> Void) {
        let dreamRequest = DreamRequest(title: title, content: content, date: date)
        
        isLoading = true
        errorMessage = nil
        
        // 检查是否有默认分享空间
        let settings = UserSettings.load()
        if let spaceId = settings.defaultShareSpaceId {
            // 先添加到个人梦境
            apiService.createDream(dream: dreamRequest) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let personalDream):
                        // 先添加个人梦境到列表
                        self.dreams.append(personalDream)
                        
                        // 再添加到空间
                        self.apiService.createSpaceDream(spaceId: spaceId, dream: dreamRequest) { [weak self] result in
                            guard let self = self else { return }
                            
                            DispatchQueue.main.async {
                                self.isLoading = false
                                
                                switch result {
                                case .success(_):
                                    // 空间梦境也添加成功，但不添加到dreams列表，因为已经添加过个人梦境了
                                    // 只需排序现有的梦境列表
                                    self.dreams.sort(by: { $0.date > $1.date })
                                    completion(true)
                                case .failure(let error):
                                    self.handleError(error)
                                    // 个人梦境已添加成功，所以仍然返回true
                                    completion(true)
                                }
                            }
                        }
                    case .failure(let error):
                        self.isLoading = false
                        self.handleError(error)
                        completion(false)
                    }
                }
            }
        } else {
            // 添加到个人梦境
            apiService.createDream(dream: dreamRequest) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let newDream):
                        self?.dreams.append(newDream)
                        self?.dreams.sort(by: { $0.date > $1.date })
                        completion(true)
                    case .failure(let error):
                        self?.handleError(error)
                        completion(false)
                    }
                }
            }
        }
    }
    
    func updateDream(id: String, title: String, content: String, date: String, completion: @escaping (Bool) -> Void) {
        let dreamRequest = DreamRequest(title: title, content: content, date: date)
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateDream(id: id, dream: dreamRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let updatedDream):
                    if let index = self?.dreams.firstIndex(where: { $0.id == id }) {
                        self?.dreams[index] = updatedDream
                    }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    func deleteDream(id: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        apiService.deleteDream(id: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    self?.dreams.removeAll { $0.id == id }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    func shareDreamToSpace(dream: Dream, spaceId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let dreamRequest = DreamRequest(title: dream.title, content: dream.content, date: dream.date)
        
        // 创建空间梦境
        apiService.createSpaceDream(spaceId: spaceId, dream: dreamRequest) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    // 分享成功后重新加载梦境列表以确保没有重复项
                    self.fetchDreams()
                    completion(true)
                case .failure(let error):
                    self.handleError(error)
                    completion(false)
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
