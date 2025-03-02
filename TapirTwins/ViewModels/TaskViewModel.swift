import Foundation
import SwiftUI
import UIKit

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var taskRecords: [TaskRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let spaceService = SpaceService.shared
    
    func fetchTasks() {
        isLoading = true
        errorMessage = nil
        
        print("开始获取任务列表...")
        
        // 先获取个人任务
        apiService.fetchTasks { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let personalTasks):
                    print("成功获取到 \(personalTasks.count) 个个人任务")
                    
                    // 检查是否有默认空间，如果有，则获取该空间的任务
                    let settings = UserSettings.load()
                    if let defaultSpaceId = settings.defaultShareSpaceId {
                        // 获取空间任务并合并
                        self?.fetchSpaceTasksAndMerge(spaceId: defaultSpaceId, personalTasks: personalTasks)
                    } else {
                        // 没有默认空间，只显示个人任务
                        self?.sortAndSetTasks(personalTasks)
                        self?.isLoading = false
                    }
                    
                case .failure(let error):
                    print("获取个人任务失败: \(error)")
                    self?.handleError(error)
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func fetchSpaceTasksAndMerge(spaceId: String, personalTasks: [Task]) {
        print("开始获取空间任务，空间ID: \(spaceId)")
        
        spaceService.fetchSpaceTasks(spaceId: spaceId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let spaceTasks):
                    print("成功获取到 \(spaceTasks.count) 个空间任务")
                    
                    // 合并个人任务和空间任务
                    var allTasks = personalTasks
                    
                    // 将空间任务添加到任务数组
                    allTasks.append(contentsOf: spaceTasks)
                    
                    // 排序并设置任务
                    self?.sortAndSetTasks(allTasks)
                    
                case .failure(let error):
                    print("获取空间任务失败: \(error)")
                    // 即使获取空间任务失败，也显示个人任务
                    self?.sortAndSetTasks(personalTasks)
                }
            }
        }
    }
    
    private func sortAndSetTasks(_ tasks: [Task]) {
        // 按照完成状态和截止日期排序
        self.tasks = tasks.sorted { task1, task2 in
            if task1.completedToday != task2.completedToday {
                return !task1.completedToday
            }
            
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                return task1.createdAt > task2.createdAt
            }
            
            return date1 < date2
        }
        
        print("任务排序完成，当前任务数量: \(self.tasks.count)")
    }
    
    func fetchTaskRecords(id: String) {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchTaskRecords(taskId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let records):
                    self?.taskRecords = records.sorted(by: { $0.createdAt > $1.createdAt })
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    func fetchTodayRecords() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchTodayRecords { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let records):
                    self?.taskRecords = records
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    func addTask(title: String, description: String?, dueDate: String?, requiredImages: Int, spaceId: String? = nil, completion: @escaping (Bool) -> Void) {
        let taskRequest = TaskRequest(
            title: title,
            description: description,
            dueDate: dueDate,
            requiredImages: requiredImages,
            spaceId: spaceId
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.createTask(task: taskRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let newTask):
                    self?.tasks.append(newTask)
                    self?.sortAndSetTasks(self?.tasks ?? [])
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    func updateTask(id: String, title: String, description: String?, dueDate: String?, requiredImages: Int, spaceId: String? = nil, completion: @escaping (Bool) -> Void) {
        let taskRequest = TaskRequest(
            title: title,
            description: description,
            dueDate: dueDate,
            requiredImages: requiredImages,
            spaceId: spaceId
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateTask(id: id, task: taskRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let updatedTask):
                    if let index = self?.tasks.firstIndex(where: { $0.id == id }) {
                        self?.tasks[index] = updatedTask
                        self?.sortAndSetTasks(self?.tasks ?? [])
                    }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    func completeTask(id: String, images: [UIImage], completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 将UIImage转换为base64字符串
        var base64Images: [String] = []
        for image in images {
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                let base64String = "data:image/jpeg;base64," + imageData.base64EncodedString()
                base64Images.append(base64String)
            }
        }
        
        if base64Images.isEmpty {
            errorMessage = "图片转换失败"
            completion(false)
            return
        }
        
        apiService.completeTask(id: id, images: base64Images) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        // 更新任务列表
                        self?.fetchTasks()
                        completion(true)
                    } else {
                        self?.errorMessage = response.message
                        completion(false)
                    }
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    func deleteTask(taskId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        isLoading = true
        errorMessage = nil
        
        apiService.deleteTask(id: taskId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    self?.tasks.removeAll { $0.id == taskId }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 审批空间任务记录
    func approveSpaceTaskRecord(spaceId: String, recordId: String, comment: String = "", completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始审批空间任务记录，空间ID: \(spaceId)，记录ID: \(recordId)")
        
        spaceService.approveTaskRecord(spaceId: spaceId, recordId: recordId, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("空间任务审批成功: \(response.message)")
                    // 刷新任务列表
                    self?.fetchTasks()
                    completion(true)
                case .failure(let error):
                    print("空间任务审批失败: \(error)")
                    if let apiError = error as? APIError {
                        self?.handleError(apiError)
                    } else {
                        self?.errorMessage = "审批失败: \(error.localizedDescription)"
                    }
                    completion(false)
                }
            }
        }
    }
    
    // 拒绝空间任务记录
    func rejectSpaceTaskRecord(spaceId: String, recordId: String, reason: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始拒绝空间任务记录，空间ID: \(spaceId)，记录ID: \(recordId)，原因: \(reason)")
        
        spaceService.rejectTaskRecord(spaceId: spaceId, recordId: recordId, reason: reason) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("空间任务拒绝成功: \(response.message)")
                    // 刷新任务列表
                    self?.fetchTasks()
                    completion(true)
                case .failure(let error):
                    print("空间任务拒绝失败: \(error)")
                    if let apiError = error as? APIError {
                        self?.handleError(apiError)
                    } else {
                        self?.errorMessage = "拒绝失败: \(error.localizedDescription)"
                    }
                    completion(false)
                }
            }
        }
    }
    
    // 检查用户是否有审批权限
    func checkUserIsApprover(userId: String, task: Task) -> Bool {
        // 如果任务没有spaceId，则不是空间任务
        guard let spaceId = task.spaceId else {
            return false
        }
        
        // 使用SpaceViewModel来检查权限
        let spaceViewModel = SpaceViewModel()
        
        // 如果任务有指定的审批者，检查用户是否在列表中
        if let approverIds = task.assignedApproverIds {
            if approverIds.contains(userId) {
                return true
            }
        }
        
        // 如果任务没有指定审批者，则使用SpaceViewModel检查用户角色
        // 注意：这种实现方式在实际应用中可能会有问题，因为SpaceViewModel需要时间来获取空间信息
        // 更好的方式是在应用启动时预加载空间信息，或者使用回调方式异步检查权限
        return spaceViewModel.checkUserIsApprover(userId: userId, task: task)
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
