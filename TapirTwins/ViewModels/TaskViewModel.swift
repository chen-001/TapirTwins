import Foundation
import SwiftUI
import UIKit

class TaskViewModel: ObservableObject {
    @Published var tasks: [TapirTask] = []
    @Published var taskRecords: [TaskRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var monthlyTaskStats: MonthlyTaskStats?
    @Published var isLoadingStats = false
    @Published var allTasks: [TapirTask] = []
    @Published var allTaskRecords: [TaskRecord] = []
    @Published var statisticsStartDate: Date? = nil
    @Published var totalFailedCount: Int = 0
    
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
    
    private func fetchSpaceTasksAndMerge(spaceId: String, personalTasks: [TapirTask]) {
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
    
    private func sortAndSetTasks(_ tasks: [TapirTask]) {
        // 保存所有任务
        self.allTasks = tasks
        
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
        
        // 图片压缩和处理
        var base64Images: [String] = []
        let compressionGroup = DispatchGroup()
        
        for image in images {
            compressionGroup.enter()
            
            // 在后台线程中进行图片处理
            DispatchQueue.global(qos: .userInitiated).async {
                // 获取原始图片大小
                let originalData = image.jpegData(compressionQuality: 1.0)
                print("原始图片大小: \(originalData?.count ?? 0) 字节 (\((originalData?.count ?? 0) / 1024) KB)")
                
                // 1. 首先调整图片大小（如果必要）
                let resizedImage = self.resizeImageIfNeeded(image, maxDimension: 1200)
                
                // 2. 压缩图片
                if let compressedImageData = self.compressImage(resizedImage, maxSizeKB: 500) {
                    print("压缩后图片大小: \(compressedImageData.count) 字节 (\(compressedImageData.count / 1024) KB)")
                    let base64String = "data:image/jpeg;base64," + compressedImageData.base64EncodedString()
                    base64Images.append(base64String)
                }
                
                compressionGroup.leave()
            }
        }
        
        // 等待所有图片处理完成
        compressionGroup.notify(queue: .main) {
            if base64Images.isEmpty {
                self.errorMessage = "图片处理失败"
                self.isLoading = false
                completion(false)
                return
            }
            
            self.apiService.completeTask(id: id, images: base64Images) { [weak self] result in
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
    }
    
    // 调整图片尺寸
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let currentWidth = image.size.width
        let currentHeight = image.size.height
        
        // 如果图片尺寸已经在合理范围内，不需要调整
        if currentWidth <= maxDimension && currentHeight <= maxDimension {
            return image
        }
        
        // 确定新的尺寸
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if currentWidth > currentHeight {
            newWidth = maxDimension
            newHeight = (currentHeight / currentWidth) * maxDimension
        } else {
            newHeight = maxDimension
            newWidth = (currentWidth / currentHeight) * maxDimension
        }
        
        // 创建新的图像上下文
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // 压缩图片
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        // 最大尺寸（以字节为单位）
        let maxSize = maxSizeKB * 1024
        
        // 初始压缩质量
        var compression: CGFloat = 0.9
        let minCompression: CGFloat = 0.1
        
        // 转换为JPEG数据
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // 如果初始压缩后的图片已经小于最大尺寸，直接返回
        if imageData.count < maxSize {
            return imageData
        }
        
        // 二分法查找最佳压缩率
        var max: CGFloat = 1.0
        var min: CGFloat = 0.0
        
        for _ in 0..<6 { // 最多尝试6次压缩
            compression = (max + min) / 2
            
            if let data = image.jpegData(compressionQuality: compression) {
                if data.count < maxSize {
                    min = compression
                    imageData = data
                } else {
                    max = compression
                }
            }
            
            if max - min < 0.01 {
                break
            }
        }
        
        // 如果二分法后仍然超过最大尺寸，则再次尝试更低的压缩质量
        if imageData.count > maxSize, let finalData = image.jpegData(compressionQuality: minCompression) {
            return finalData
        }
        
        return imageData
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
    func checkUserIsApprover(userId: String, task: TapirTask) -> Bool {
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
    
    func fetchMonthlyTaskStats(month: String, completion: @escaping (Bool) -> Void) {
        isLoadingStats = true
        errorMessage = nil
        
        print("开始在前端计算\(month)月份任务统计...")
        
        // 获取月份的开始和结束日期
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        guard let monthDate = formatter.date(from: month) else {
            isLoadingStats = false
            errorMessage = "无效的月份格式"
            completion(false)
            return
        }
        
        // 获取所有任务
        let tasksToProcess = self.allTasks
        
        // 本地生成月度统计数据
        generateMonthlyStats(month: month, monthDate: monthDate, tasks: tasksToProcess) { [weak self] stats in
            DispatchQueue.main.async {
                self?.isLoadingStats = false
                self?.monthlyTaskStats = stats
                completion(true)
                print("本地计算的月度任务统计数据生成完成，共有 \(stats.dailyStats.count) 天的数据")
            }
        }
    }
    
    private func generateMonthlyStats(month: String, monthDate: Date, tasks: [TapirTask], completion: @escaping (MonthlyTaskStats) -> Void) {
        // 创建一个包含当月所有日期的字典，值为未完成任务计数（初始为0）
        var dailyStats: [String: Int] = [:]
        
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthDate)!
        let firstDayComponents = calendar.dateComponents([.year, .month], from: monthDate)
        
        // 初始化日历：为本月的每一天创建一个统计项
        for day in 1...range.count {
            var dateComponents = firstDayComponents
            dateComponents.day = day
            
            if let date = calendar.date(from: dateComponents) {
                // 检查日期是否在今天或之前
                if date <= Date() {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let dateString = formatter.string(from: date)
                    dailyStats[dateString] = 0
                }
            }
        }
        
        // 异步处理所有任务的记录
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            
            for task in tasks {
                dispatchGroup.enter()
                
                // 获取任务的所有记录
                self.fetchTaskRecordsForStats(taskId: task.id) { records in
                    // 处理记录，检查每个日期的状态
                    for (dateString, _) in dailyStats {
                        // 查找该日期的记录
                        if let record = records.first(where: { $0.date == dateString }) {
                            // 检查记录状态
                            if record.status != .approved {
                                // 如果状态不是已批准，增加未完成任务计数
                                dailyStats[dateString] = (dailyStats[dateString] ?? 0) + 1
                            }
                        } else {
                            // 如果没有该日期的记录，表示未提交，增加未完成任务计数
                            dailyStats[dateString] = (dailyStats[dateString] ?? 0) + 1
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // 转换字典为数组
                var dailyStatsArray: [DailyTaskStats] = []
                
                for (dateString, count) in dailyStats {
                    let stat = DailyTaskStats(
                        id: dateString,
                        date: dateString,
                        failedTasksCount: count
                    )
                    dailyStatsArray.append(stat)
                }
                
                // 按日期排序
                dailyStatsArray.sort { $0.date > $1.date }
                
                // 创建MonthlyTaskStats对象
                let stats = MonthlyTaskStats(
                    month: month,
                    dailyStats: dailyStatsArray
                )
                
                // 返回结果
                completion(stats)
            }
        }
    }
    
    // 获取任务记录用于统计
    private func fetchTaskRecordsForStats(taskId: String, completion: @escaping ([TaskRecord]) -> Void) {
        // 首先检查缓存中是否已有该任务的记录
        let cachedRecords = self.allTaskRecords.filter { $0.taskId == taskId }
        if !cachedRecords.isEmpty {
            completion(cachedRecords)
            return
        }
        
        // 如果没有缓存，则从API获取
        apiService.fetchTaskRecords(taskId: taskId) { result in
            switch result {
            case .success(let records):
                // 缓存记录
                DispatchQueue.main.async {
                    self.allTaskRecords.append(contentsOf: records)
                }
                completion(records)
            case .failure:
                completion([])
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
    
    // 保存统计起始日期到后端
    func saveStatisticsStartDate(date: Date, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 格式化日期为字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 检查是否有默认空间
        let settings = UserSettings.load()
        
        if let spaceId = settings.defaultShareSpaceId {
            // 如果有默认空间，保存到空间设置（共享）
            saveSpaceStatisticsStartDate(date: date, spaceId: spaceId, completion: completion)
        } else {
            // 如果没有默认空间，保存到个人设置
            savePersonalStatisticsStartDate(date: date, completion: completion)
        }
    }
    
    // 保存个人统计起始日期
    private func savePersonalStatisticsStartDate(date: Date, completion: @escaping (Bool) -> Void) {
        // 格式化日期为字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 创建请求参数
        let settingsRequest = UserSettingsRequest(statisticsStartDate: dateString)
        
        print("保存个人统计起始日期: \(dateString)")
        
        // 调用API保存设置
        apiService.updateUserSettings(settings: settingsRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 更新本地存储的起始日期
                    self?.statisticsStartDate = date
                    // 保存到本地设置
                    var settings = UserSettings.load()
                    settings.statisticsStartDate = dateString
                    settings.save()
                    
                    print("个人统计起始日期保存成功")
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    print("个人统计起始日期保存失败: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    // 保存空间统计起始日期（共享）
    private func saveSpaceStatisticsStartDate(date: Date, spaceId: String, completion: @escaping (Bool) -> Void) {
        // 格式化日期为字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        print("保存空间统计起始日期: \(dateString), 空间ID: \(spaceId)")
        
        // 调用空间服务保存设置
        spaceService.updateSpaceStatisticsStartDate(spaceId: spaceId, startDate: dateString) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 更新本地存储的起始日期
                    self?.statisticsStartDate = date
                    // 保存到本地设置（备份）
                    var settings = UserSettings.load()
                    settings.statisticsStartDate = dateString
                    settings.save()
                    
                    print("空间统计起始日期保存成功")
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    print("空间统计起始日期保存失败: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    // 加载统计起始日期
    func loadStatisticsStartDate() {
        // 检查是否有默认空间
        let settings = UserSettings.load()
        
        if let spaceId = settings.defaultShareSpaceId {
            // 如果有默认空间，从空间设置加载（共享）
            loadSpaceStatisticsStartDate(spaceId: spaceId)
        } else {
            // 如果没有默认空间，从个人设置加载
            loadPersonalStatisticsStartDate()
        }
    }
    
    // 从个人设置加载统计起始日期
    private func loadPersonalStatisticsStartDate() {
        // 从本地设置加载
        let settings = UserSettings.load()
        if let dateString = settings.statisticsStartDate, !dateString.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                self.statisticsStartDate = date
                print("从本地加载个人统计起始日期: \(dateString)")
                return
            }
        }
        
        // 如果本地没有设置，使用当前日期
        self.statisticsStartDate = Date()
        print("未找到个人统计起始日期，使用当前日期")
    }
    
    // 从空间设置加载统计起始日期（共享）
    private func loadSpaceStatisticsStartDate(spaceId: String) {
        print("尝试从空间加载统计起始日期, 空间ID: \(spaceId)")
        
        // 从空间服务加载
        spaceService.fetchSpaceStatisticsStartDate(spaceId: spaceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dateString):
                    if !dateString.isEmpty {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: dateString) {
                            self?.statisticsStartDate = date
                            // 同步到本地设置
                            var settings = UserSettings.load()
                            settings.statisticsStartDate = dateString
                            settings.save()
                            
                            print("从空间加载统计起始日期成功: \(dateString)")
                            return
                        }
                    }
                    
                    // 如果加载失败或日期无效，回退到个人设置
                    self?.loadPersonalStatisticsStartDate()
                    
                case .failure(let error):
                    print("从空间加载统计起始日期失败: \(error)")
                    // 加载失败，回退到个人设置
                    self?.loadPersonalStatisticsStartDate()
                }
            }
        }
    }
    
    // 计算从起始日期到今天的累计失败次数
    func calculateTotalFailedCount(completion: @escaping (Int) -> Void) {
        guard let startDate = statisticsStartDate else {
            completion(0)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("开始计算从 \(startDate) 到今天的累计失败次数...")
        
        // 获取起始日期到今天的所有日期
        let dates = getDatesFromStartToToday(startDate: startDate)
        
        // 异步处理所有任务的记录
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            var totalFailed = 0
            
            for task in self.allTasks {
                dispatchGroup.enter()
                
                // 获取任务的所有记录
                self.fetchTaskRecordsForStats(taskId: task.id) { records in
                    // 处理记录，检查每个日期的状态
                    for dateString in dates {
                        // 查找该日期的记录
                        if let record = records.first(where: { $0.date == dateString }) {
                            // 检查记录状态
                            if record.status != .approved {
                                // 如果状态不是已批准，增加失败次数
                                totalFailed += 1
                            }
                        } else {
                            // 如果没有该日期的记录，表示未提交，增加失败次数
                            totalFailed += 1
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false
                self.totalFailedCount = totalFailed
                print("累计失败次数计算完成: \(totalFailed)")
                completion(totalFailed)
            }
        }
    }
    
    // 获取从起始日期到今天的所有日期字符串
    private func getDatesFromStartToToday(startDate: Date) -> [String] {
        var dates: [String] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 确保起始日期不超过当前日期
        let safeStartDate = min(startDate, Date())
        
        // 当前日期
        let endDate = Date()
        
        // 计算日期差异
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: safeStartDate), to: calendar.startOfDay(for: endDate))
        
        if let days = components.day, days >= 0 {
            // 添加从起始日期到今天的每一天
            for i in 0...days {
                if let date = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: safeStartDate)) {
                    let dateString = dateFormatter.string(from: date)
                    dates.append(dateString)
                }
            }
        }
        
        return dates
    }
}
