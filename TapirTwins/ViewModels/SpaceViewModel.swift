import Foundation
import SwiftUI

class SpaceViewModel: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var currentSpace: Space?
    @Published var spaceDreams: [Dream] = []
    @Published var spaceTasks: [TapirTask] = []
    @Published var taskRecords: [TaskRecord] = []
    @Published var todayRecords: [TaskRecord] = []
    
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var taskHistoryRecords: [HistoryRecord] = []
    
    private let spaceService = SpaceService.shared
    
    // MARK: - 空间管理
    
    func fetchSpaces() {
        isLoading = true
        
        spaceService.fetchSpaces { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let spaces):
                    self.spaces = spaces
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func fetchSpace(id: String) {
        isLoading = true
        
        spaceService.fetchSpace(id: id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func createSpace(name: String, description: String) {
        isLoading = true
        
        spaceService.createSpace(name: name, description: description) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    self.spaces.append(space)
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func joinSpace(inviteCode: String) {
        isLoading = true
        
        spaceService.joinSpace(inviteCode: inviteCode) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    self.spaces.append(space)
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func updateSpace(id: String, name: String, description: String) {
        isLoading = true
        
        spaceService.updateSpace(id: id, name: name, description: description) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    if let index = self.spaces.firstIndex(where: { $0.id == space.id }) {
                        self.spaces[index] = space
                    }
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func deleteSpace(id: String) {
        isLoading = true
        
        spaceService.deleteSpace(id: id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    self.spaces.removeAll(where: { $0.id == id })
                    if self.currentSpace?.id == id {
                        self.currentSpace = nil
                    }
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 成员管理
    
    func fetchSpaceMembers(spaceId: String) {
        // 这个方法实际上不需要额外的API调用，因为成员信息已经包含在Space对象中
        // 当fetchSpace被调用时，成员信息已经加载
        // 这里只是为了保持API一致性
        print("获取空间成员信息，空间ID: \(spaceId)")
        
        // 如果currentSpace为空，则尝试获取空间信息
        if currentSpace == nil {
            fetchSpace(id: spaceId)
        }
    }
    
    func inviteMember(spaceId: String, username: String, role: MemberRole) {
        isLoading = true
        
        spaceService.inviteMember(spaceId: spaceId, username: username, role: role) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    if let index = self.spaces.firstIndex(where: { $0.id == space.id }) {
                        self.spaces[index] = space
                    }
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func removeMember(spaceId: String, userId: String) {
        isLoading = true
        
        spaceService.removeMember(spaceId: spaceId, userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    if let index = self.spaces.firstIndex(where: { $0.id == space.id }) {
                        self.spaces[index] = space
                    }
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func updateMemberRole(spaceId: String, userId: String, role: MemberRole) {
        isLoading = true
        
        spaceService.updateMemberRole(spaceId: spaceId, userId: userId, role: role) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let space):
                    if let index = self.spaces.firstIndex(where: { $0.id == space.id }) {
                        self.spaces[index] = space
                    }
                    self.currentSpace = space
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 梦境管理
    
    func fetchSpaceDreams(spaceId: String) {
        isLoading = true
        
        spaceService.fetchSpaceDreams(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let dreams):
                    self.spaceDreams = dreams
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func createSpaceDream(spaceId: String, title: String, content: String, date: Date) {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = dateFormatter.string(from: date)
        
        let dream = DreamRequest(title: title, content: content, date: dateString)
        
        spaceService.createSpaceDream(spaceId: spaceId, dream: dream) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let dream):
                    self.spaceDreams.append(dream)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 任务管理
    
    func fetchSpaceTasks(spaceId: String) {
        isLoading = true
        
        print("开始获取空间任务，空间ID: \(spaceId)")
        
        spaceService.fetchSpaceTasks(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let tasks):
                    print("成功获取到 \(tasks.count) 个空间任务")
                    
                    // 检查任务数据
                    if tasks.isEmpty {
                        print("警告: 没有获取到任何空间任务")
                    } else {
                        for (index, task) in tasks.enumerated() {
                            print("空间任务 \(index + 1): ID=\(task.id), 标题=\(task.title)")
                        }
                    }
                    
                    self.spaceTasks = tasks
                    
                case .failure(let error):
                    print("获取空间任务失败: \(error)")
                    
                    // 清空任务列表，避免显示旧数据
                    self.spaceTasks = []
                    
                    // 显示错误信息
                    self.errorMessage = "获取任务失败: \(error.localizedDescription)"
                    self.showError = true
                    
                    // 记录详细错误信息
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(let code):
                            print("HTTP错误: \(code)")
                        case .serverError(let message):
                            print("服务器错误: \(message)")
                        case .decodingFailed(let decodingError):
                            print("解码错误: \(decodingError)")
                            
                            if let decodingError = decodingError as? DecodingError {
                                switch decodingError {
                                case .keyNotFound(let key, let context):
                                    print("解码错误: 找不到键 \(key.stringValue), 路径: \(context.codingPath)")
                                case .valueNotFound(let type, let context):
                                    print("解码错误: 找不到值, 类型: \(type), 路径: \(context.codingPath)")
                                case .typeMismatch(let type, let context):
                                    print("解码错误: 类型不匹配, 类型: \(type), 路径: \(context.codingPath)")
                                case .dataCorrupted(let context):
                                    print("解码错误: 数据损坏, 路径: \(context.codingPath), 描述: \(context.debugDescription)")
                                @unknown default:
                                    print("解码错误: 未知解码错误")
                                }
                            }
                        default:
                            print("其他网络错误: \(networkError)")
                        }
                    }
                }
            }
        }
    }
    
    func createSpaceTask(spaceId: String, title: String, description: String, dueDate: Date, requiredImages: Int, 
                         assignedSubmitterId: String? = nil, assignedApproverIds: [String]? = nil) {
        isLoading = true
        print("开始创建空间任务: \(title)，空间ID: \(spaceId)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dueDateString = dateFormatter.string(from: dueDate)
        
        let task = TaskRequest(
            title: title, 
            description: description, 
            dueDate: dueDateString, 
            requiredImages: requiredImages, 
            spaceId: spaceId,
            assignedSubmitterId: assignedSubmitterId,
            assignedApproverIds: assignedApproverIds
        )
        
        // 打印请求内容以便调试
        if let taskData = try? JSONEncoder().encode(task),
           let taskString = String(data: taskData, encoding: .utf8) {
            print("任务请求内容: \(taskString)")
        }
        
        spaceService.createSpaceTask(spaceId: spaceId, task: task) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let task):
                    print("创建空间任务成功: \(task.title)，ID: \(task.id)")
                    // 将新任务添加到列表中
                    if !self.spaceTasks.contains(where: { $0.id == task.id }) {
                        self.spaceTasks.append(task)
                    }
                    
                    // 多次重试刷新机制，确保数据同步
                    self.refreshSpaceTasksWithRetry(spaceId: spaceId, retryCount: 3, delay: 1.0)
                    
                case .failure(let error):
                    print("创建空间任务失败: \(error)")
                    
                    // 显示错误信息
                    self.errorMessage = "创建任务失败: \(error.localizedDescription)"
                    self.showError = true
                    
                    // 根据错误类型进行不同处理
                    if case .decodingFailed(let decodingError) = error {
                        print("解码错误详情: \(decodingError)")
                        
                        // 尝试重新创建任务
                        print("尝试重新创建任务...")
                        self.retryCreateTask(spaceId: spaceId, title: title, description: description, 
                                            dueDate: dueDate, requiredImages: requiredImages,
                                            assignedSubmitterId: assignedSubmitterId,
                                            assignedApproverIds: assignedApproverIds)
                    } else {
                        // 尝试重新获取任务列表
                        print("尝试重新获取任务列表...")
                        self.fetchSpaceTasks(spaceId: spaceId)
                    }
                }
            }
        }
    }
    
    // 添加重试创建任务的方法
    private func retryCreateTask(spaceId: String, title: String, description: String, dueDate: Date, 
                                requiredImages: Int, assignedSubmitterId: String? = nil, 
                                assignedApproverIds: [String]? = nil) {
        print("重试创建任务: \(title)")
        
        // 延迟一秒后重试
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let dueDateString = dateFormatter.string(from: dueDate)
            
            // 创建一个简化版的任务请求，减少可能的错误点
            let simpleTask = TaskRequest(
                title: title, 
                description: description, 
                dueDate: dueDateString, 
                requiredImages: requiredImages, 
                spaceId: spaceId,
                assignedSubmitterId: nil,  // 简化请求，不包含指定人员
                assignedApproverIds: nil   // 简化请求，不包含指定人员
            )
            
            self.spaceService.createSpaceTask(spaceId: spaceId, task: simpleTask) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let task):
                        print("重试创建任务成功: \(task.title)")
                        if !self.spaceTasks.contains(where: { $0.id == task.id }) {
                            self.spaceTasks.append(task)
                        }
                        self.fetchSpaceTasks(spaceId: spaceId)
                    case .failure(let error):
                        print("重试创建任务失败: \(error)")
                        // 最后尝试刷新任务列表
                        self.fetchSpaceTasks(spaceId: spaceId)
                    }
                }
            }
        }
    }
    
    private func refreshSpaceTasksWithRetry(spaceId: String, retryCount: Int, delay: TimeInterval) {
        guard retryCount > 0 else { return }
        
        print("刷新空间任务列表，剩余重试次数: \(retryCount)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.spaceService.fetchSpaceTasks(spaceId: spaceId) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let tasks):
                        print("成功获取到 \(tasks.count) 个任务")
                        self.spaceTasks = tasks
                        
                        // 如果仍需重试，继续下一次刷新
                        self.refreshSpaceTasksWithRetry(spaceId: spaceId, retryCount: retryCount - 1, delay: delay)
                        
                    case .failure(let error):
                        print("获取任务失败: \(error)，将重试")
                        // 失败后继续重试
                        self.refreshSpaceTasksWithRetry(spaceId: spaceId, retryCount: retryCount - 1, delay: delay)
                    }
                }
            }
        }
    }
    
    func fetchTaskRecords(spaceId: String, taskId: String? = nil, completion: ((Bool, String?) -> Void)? = nil) {
        isLoading = true
        print("开始获取空间任务记录，空间ID: \(spaceId)" + (taskId != nil ? "，任务ID: \(taskId!)" : ""))
        
        spaceService.fetchSpaceTaskRecords(spaceId: spaceId) { [weak self] (result: Result<[TaskRecord], APIError>) in
            guard let self = self else { 
                completion?(false, "视图模型已被释放")
                return 
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let records):
                    print("成功获取到 \(records.count) 条任务记录")
                    
                    // 检查任务记录数据
                    if records.isEmpty {
                        print("警告: 没有获取到任何任务记录")
                    } else {
                        for (index, record) in records.enumerated() {
                            print("任务记录 \(index + 1): ID=\(record.id), 任务ID=\(record.taskId), 状态=\(record.status.rawValue)")
                        }
                    }
                    
                    if let taskId = taskId {
                        // 如果提供了任务ID，则只显示该任务的记录
                        let filteredRecords = records.filter { $0.taskId == taskId }
                        print("过滤后的任务记录数量: \(filteredRecords.count)")
                        self.taskRecords = filteredRecords
                    } else {
                        self.taskRecords = records
                    }
                    
                    // 调用成功回调
                    completion?(true, nil)
                    
                case .failure(let error):
                    print("获取任务记录失败: \(error)")
                    self.handleError(error)
                    
                    // 调用失败回调
                    let errorMsg: String
                    switch error {
                    case .serverError(let message):
                        errorMsg = message
                    case .requestFailed(let err):
                        errorMsg = "请求失败: \(err.localizedDescription)"
                    case .decodingFailed(let err):
                        errorMsg = "解码失败: \(err.localizedDescription)"
                    case .invalidURL:
                        errorMsg = "无效URL"
                    case .invalidResponse:
                        errorMsg = "无效响应"
                    case .unknown:
                        errorMsg = "未知错误"
                    case .unauthorized:
                        errorMsg = "未授权，请重新登录"
                    case .noData:
                        errorMsg = "没有数据返回"
                    }
                    
                    completion?(false, errorMsg)
                }
            }
        }
    }
    
    func fetchSpaceTodayRecords(spaceId: String) {
        isLoading = true
        
        spaceService.fetchSpaceTodayRecords(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let records):
                    self.todayRecords = records
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func approveTaskRecord(spaceId: String, recordId: String, comment: String = "") {
        isLoading = true
        print("开始审批任务记录，空间ID: \(spaceId)，记录ID: \(recordId)，审批词: \(comment)")
        
        spaceService.approveTaskRecord(spaceId: spaceId, recordId: recordId, comment: comment) { [weak self] result in
            guard let self = self else { 
                print("SpaceViewModel已被释放，无法处理审批结果")
                return 
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("任务审批成功: \(response.message)")
                    
                    // 如果有历史记录，添加到本地
                    if let historyRecord = response.historyRecord {
                        print("收到历史记录: \(historyRecord.description)")
                        // 这里可以添加历史记录到本地存储或模型中
                    }
                    
                    // 更新记录状态
                    print("开始更新任务记录状态")
                    self.fetchTaskRecords(spaceId: spaceId)
                    self.fetchSpaceTodayRecords(spaceId: spaceId)
                    
                    // 发送通知，通知UI更新
                    NotificationCenter.default.post(name: NSNotification.Name("TaskApproved"), object: nil)
                case .failure(let error):
                    print("任务审批失败: \(error)")
                    print("错误详情: \(error.localizedDescription)")
                    
                    // 使用类型模式匹配而不是条件转换
                    self.handleError(error)
                }
            }
        }
    }
    
    func rejectTaskRecord(spaceId: String, recordId: String, reason: String) {
        isLoading = true
        
        spaceService.rejectTaskRecord(spaceId: spaceId, recordId: recordId, reason: reason) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    // 更新记录状态
                    self.fetchTaskRecords(spaceId: spaceId)
                    self.fetchSpaceTodayRecords(spaceId: spaceId)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // 提交任务
    func submitTask(spaceId: String, taskId: String, images: [UIImage]) {
        isLoading = true
        
        spaceService.submitTask(spaceId: spaceId, taskId: taskId, images: images) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    // 更新任务状态
                    self.fetchSpaceTasks(spaceId: spaceId)
                    self.fetchTaskRecords(spaceId: spaceId)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 用户角色检查
    
    func checkUserIsApprover(userId: String, spaceId: String, completion: @escaping (Bool) -> Void) {
        // 首先检查是否已经有空间数据
        if let space = currentSpace, space.id == spaceId {
            // 如果已有空间数据，直接检查用户角色
            let isApprover = space.members.contains { member in
                return member.userId == userId && (member.role == .approver || member.role == .admin)
            }
            completion(isApprover)
            return
        }
        
        // 如果没有空间数据，先获取空间数据
        spaceService.fetchSpace(id: spaceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let space):
                    self?.currentSpace = space
                    let isApprover = space.members.contains { member in
                        return member.userId == userId && (member.role == .approver || member.role == .admin)
                    }
                    completion(isApprover)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    // 检查用户是否是指定的任务打卡者
    func checkUserIsAssignedSubmitter(userId: String, task: TapirTask) -> Bool {
        // 如果任务没有指定打卡者，任何成员都可以打卡
        if task.assignedSubmitterId == nil {
            return true
        }
        
        // 检查用户是否是指定的打卡者
        return task.assignedSubmitterId == userId
    }
    
    // 检查用户是否是指定的任务审阅者
    func checkUserIsAssignedApprover(userId: String, taskRecord: TaskRecord) -> Bool {
        // 如果任务记录没有指定审阅者，任何审阅者角色的成员都可以审阅
        if taskRecord.assignedApproverIds == nil || taskRecord.assignedApproverIds?.isEmpty == true {
            return true
        }
        
        // 检查用户是否是指定的审阅者之一
        return taskRecord.assignedApproverIds?.contains(userId) == true
    }
    
    // MARK: - 任务历史记录
    
    // 获取任务历史记录
    func fetchTaskHistory(spaceId: String, taskId: String, completion: ((Bool, String?) -> Void)? = nil) {
        isLoading = true
        print("开始获取任务历史记录，空间ID: \(spaceId)，任务ID: \(taskId)")
        
        spaceService.fetchTaskHistory(spaceId: spaceId, taskId: taskId) { [weak self] result in
            guard let self = self else {
                completion?(false, "视图模型已被释放")
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let records):
                    print("成功获取到 \(records.count) 条历史记录")
                    self.taskHistoryRecords = records
                    completion?(true, nil)
                    
                case .failure(let error):
                    print("获取历史记录失败: \(error)")
                    self.handleError(error)
                    completion?(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 错误处理
    
    private func handleError(_ error: Error) {
        print("处理错误: \(error)")
        
        // 根据错误类型设置错误消息
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "无效URL"
            case .invalidResponse:
                errorMessage = "无效响应"
            case .requestFailed(let err):
                errorMessage = "请求失败: \(err.localizedDescription)"
            case .decodingFailed(let err):
                errorMessage = "解码失败: \(err.localizedDescription)"
            case .serverError(let message):
                errorMessage = "服务器错误: \(message)"
            case .unknown:
                errorMessage = "未知错误"
            case .unauthorized:
                errorMessage = "未授权，请重新登录"
            case .noData:
                errorMessage = "没有数据返回"
            }
        } else if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                errorMessage = "无效URL"
            case .invalidResponse:
                errorMessage = "无效响应"
            case .httpError(let code):
                errorMessage = "HTTP错误: \(code)"
            case .noData:
                errorMessage = "没有数据返回"
            case .decodingFailed(let err):
                errorMessage = "解码失败: \(err.localizedDescription)"
            case .serverError(let message):
                errorMessage = "服务器错误: \(message)"
            case .unknown:
                errorMessage = "未知错误"
            case .unauthorized:
                errorMessage = "未授权，请重新登录"
            }
        } else {
            errorMessage = "发生错误: \(error.localizedDescription)"
        }
        
        showError = true
    }
    
    // 公共方法：检查用户是否有审批权限
    func checkUserIsApprover(userId: String, task: TapirTask) -> Bool {
        // 如果任务没有spaceId，则不是空间任务
        guard let spaceId = task.spaceId else {
            return false
        }
        
        // 如果任务有指定的审批者，检查用户是否在列表中
        if let approverIds = task.assignedApproverIds {
            if approverIds.contains(userId) {
                return true
            }
        }
        
        // 如果任务没有指定审批者，则检查用户在空间中的角色
        let space = spaces.first(where: { $0.id == spaceId })
        guard let currentSpace = space else {
            // 如果找不到空间，尝试获取空间信息
            fetchSpace(id: spaceId)
            return false
        }
        
        // 查找用户在空间中的成员信息
        let member = currentSpace.members.first(where: { $0.userId == userId })
        guard let memberInfo = member else {
            return false
        }
        
        // 检查用户角色是否为审批者或管理员
        return memberInfo.role == .approver || memberInfo.role == .admin
    }
}