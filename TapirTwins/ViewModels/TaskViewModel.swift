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
        // 先展示已有的缓存任务数据（如果有）
        let hasCachedTasks = !self.allTasks.isEmpty
        if hasCachedTasks {
            print("使用缓存的\(self.allTasks.count)个任务，同时在后台更新数据")
            self.sortAndSetTasks(self.allTasks)
        }
        
        // 设置加载状态（如果没有缓存数据，则显示加载器）
        if !hasCachedTasks {
            isLoading = true
        }
        errorMessage = nil
        
        print("开始获取任务列表...")
        
        // 先获取个人任务
        apiService.fetchTasks { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let personalTasks):
                    print("成功获取到 \(personalTasks.count) 个个人任务")
                    
                    // 检查是否有默认空间，如果有，则获取该空间的任务
                    let settings = UserSettings.load()
                    if let defaultSpaceId = settings.defaultShareSpaceId {
                        // 获取空间任务并合并
                        self.fetchSpaceTasksAndMerge(spaceId: defaultSpaceId, personalTasks: personalTasks)
                    } else {
                        // 没有默认空间，只显示个人任务
                        // 检查数据是否有变化
                        let tasksChanged = self.haveTasksChanged(self.allTasks, personalTasks)
                        if tasksChanged {
                            print("检测到任务数据变化，更新UI")
                            self.sortAndSetTasks(personalTasks)
                        } else {
                            print("任务数据无变化，无需更新UI")
                        }
                        self.isLoading = false
                    }
                    
                case .failure(let error):
                    print("获取个人任务失败: \(error)")
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchSpaceTasksAndMerge(spaceId: String, personalTasks: [TapirTask]) {
        print("开始获取空间任务，空间ID: \(spaceId)")
        
        spaceService.fetchSpaceTasks(spaceId: spaceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let spaceTasks):
                    print("成功获取到 \(spaceTasks.count) 个空间任务")
                    
                    // 合并个人任务和空间任务
                    var allTasks = personalTasks
                    
                    // 将空间任务添加到任务数组
                    allTasks.append(contentsOf: spaceTasks)
                    
                    // 检查任务是否有变化
                    let tasksChanged = self.haveTasksChanged(self.allTasks, allTasks)
                    if tasksChanged {
                        print("检测到任务数据变化（包含空间任务），更新UI")
                        // 排序并设置任务
                        self.sortAndSetTasks(allTasks)
                    } else {
                        print("任务数据无变化（包含空间任务），无需更新UI")
                    }
                    
                case .failure(let error):
                    print("获取空间任务失败: \(error)")
                    // 即使获取空间任务失败，也检查个人任务是否有变化
                    let tasksChanged = self.haveTasksChanged(self.allTasks, personalTasks)
                    if tasksChanged {
                        print("检测到任务数据变化（仅个人任务），更新UI")
                        // 排序并设置任务
                        self.sortAndSetTasks(personalTasks)
                    } else {
                        print("任务数据无变化（仅个人任务），无需更新UI")
                    }
                }
            }
        }
    }
    
    // 检查任务列表是否有变化
    private func haveTasksChanged(_ oldTasks: [TapirTask], _ newTasks: [TapirTask]) -> Bool {
        // 如果数量不同，直接认为有变化
        if oldTasks.count != newTasks.count {
            return true
        }
        
        // 创建任务ID集合进行比较
        let oldIds = Set(oldTasks.map { $0.id })
        let newIds = Set(newTasks.map { $0.id })
        
        // 如果ID集合不同，认为有变化
        if oldIds != newIds {
            return true
        }
        
        // 比较每个任务的完成状态
        for newTask in newTasks {
            if let oldTask = oldTasks.first(where: { $0.id == newTask.id }) {
                if oldTask.completedToday != newTask.completedToday {
                    return true
                }
            } else {
                // 如果找不到对应的旧任务，认为有变化
                return true
            }
        }
        
        return false
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
        // 首先检查缓存中是否有该任务的记录
        let cachedRecords = self.allTaskRecords.filter { $0.taskId == id }
        let hasCachedRecords = !cachedRecords.isEmpty
        
        // 如果有缓存记录，先显示缓存数据
        if hasCachedRecords {
            print("使用缓存的\(cachedRecords.count)条记录，同时在后台更新数据")
            self.taskRecords = cachedRecords.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        // 只有在没有缓存的情况下才显示加载状态
        if !hasCachedRecords {
            isLoading = true
        }
        errorMessage = nil
        
        // 添加随机参数，确保不返回缓存数据
        var urlParams: [String: String] = ["_nocache": UUID().uuidString]
        
        apiService.fetchTaskRecords(taskId: id, urlParams: urlParams) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let records):
                    print("从API获取任务[\(id)]记录: \(records.count)条")
                    
                    let newRecords = records.sorted(by: { $0.createdAt > $1.createdAt })
                    
                    // 检查新记录是否与缓存记录不同
                    let shouldUpdate = newRecords.count != cachedRecords.count || 
                                       !self.areRecordsEqual(newRecords, cachedRecords)
                    
                    if shouldUpdate || !hasCachedRecords {
                        print("更新任务[\(id)]的记录，从\(cachedRecords.count)条变为\(newRecords.count)条")
                        self.taskRecords = newRecords
                        
                        // 更新缓存
                        self.allTaskRecords.removeAll { $0.taskId == id }
                        self.allTaskRecords.append(contentsOf: records)
                        
                        // 打印记录ID列表以便调试
                        let recordIds = newRecords.map { $0.id }.joined(separator: ", ")
                        print("任务[\(id)]的记录IDs: \(recordIds)")
                    } else {
                        print("任务[\(id)]的记录无变化")
                    }
                    
                case .failure(let error):
                    print("获取任务[\(id)]记录失败: \(error)")
                    self.handleError(error)
                }
            }
        }
    }
    
    func fetchTodayRecords() {
        // 先检查缓存中是否有今天的记录
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let cachedTodayRecords = self.allTaskRecords.filter { $0.date == todayString }
        let hasCachedRecords = !cachedTodayRecords.isEmpty
        
        // 如果有缓存记录，先显示缓存数据
        if hasCachedRecords {
            print("使用缓存的\(cachedTodayRecords.count)条今日记录，同时在后台更新数据")
            self.taskRecords = cachedTodayRecords
        }
        
        // 只有在没有缓存的情况下才显示加载状态
        if !hasCachedRecords {
            isLoading = true
        }
        errorMessage = nil
        
        // 添加随机参数，确保不返回缓存数据
        var urlParams: [String: String] = ["_nocache": UUID().uuidString]
        
        apiService.fetchTodayRecords(urlParams: urlParams) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let records):
                    print("从API获取今日记录: \(records.count)条")
                    
                    // 检查新记录是否与缓存记录不同
                    let shouldUpdate = records.count != cachedTodayRecords.count || 
                                       !self.areRecordsEqual(records, cachedTodayRecords)
                    
                    if shouldUpdate || !hasCachedRecords {
                        print("更新今日记录，从\(cachedTodayRecords.count)条变为\(records.count)条")
                        self.taskRecords = records
                        
                        // 更新缓存，移除旧的今日记录
                        self.allTaskRecords.removeAll { $0.date == todayString }
                        self.allTaskRecords.append(contentsOf: records)
                        
                        // 打印记录ID列表以便调试
                        if !records.isEmpty {
                            let recordIds = records.map { $0.id }.joined(separator: ", ")
                            print("今日记录IDs: \(recordIds)")
                        }
                    } else {
                        print("今日记录无变化")
                    }
                    
                case .failure(let error):
                    print("获取今日记录失败: \(error)")
                    self.handleError(error)
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
        // 如果当前已有统计数据且是同一个月，先使用缓存的统计数据
        let hasCachedData = self.monthlyTaskStats != nil && self.monthlyTaskStats?.month == month
        if hasCachedData {
            print("使用缓存的\(month)月份统计数据，共\(self.monthlyTaskStats!.dailyStats.count)天的数据，同时在后台更新")
            // 直接返回成功，表示有缓存数据可用
            completion(true)
        } else {
            // 如果没有缓存的统计数据，设置加载状态
            self.isLoadingStats = true
        }
        
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
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingStats = false
                
                // 检查数据是否有变化
                let dataChanged = self.monthlyTaskStats == nil || 
                                  self.monthlyTaskStats?.month != month || 
                                  !self.areMonthlyStatsEqual(self.monthlyTaskStats!, stats)
                
                if dataChanged {
                    print("更新\(month)月份统计数据，共\(stats.dailyStats.count)天的数据")
                    self.monthlyTaskStats = stats
                    
                    // 如果之前没有数据或数据有变化，通知调用方
                    print("检测到统计数据变化，通知UI更新")
                    completion(true)
                } else {
                    print("月度统计数据无变化")
                    // 只有当之前没有缓存数据时，才需要通知调用方
                    if !hasCachedData {
                        completion(true)
                    }
                }
            }
        }
    }
    
    // 辅助方法：比较两组月度统计数据是否相同
    private func areMonthlyStatsEqual(_ stats1: MonthlyTaskStats, _ stats2: MonthlyTaskStats) -> Bool {
        // 如果月份不同，直接返回false
        if stats1.month != stats2.month {
            return false
        }
        
        // 如果天数不同，直接返回false
        if stats1.dailyStats.count != stats2.dailyStats.count {
            return false
        }
        
        // 比较每天的统计数据
        let map1 = Dictionary(uniqueKeysWithValues: stats1.dailyStats.map { ($0.date, $0.failedTasksCount) })
        let map2 = Dictionary(uniqueKeysWithValues: stats2.dailyStats.map { ($0.date, $0.failedTasksCount) })
        
        // 检查每一天的数据是否相同
        for (date, count) in map1 {
            guard let count2 = map2[date], count == count2 else {
                return false
            }
        }
        
        return true
    }
    
    private func generateMonthlyStats(month: String, monthDate: Date, tasks: [TapirTask], completion: @escaping (MonthlyTaskStats) -> Void) {
        // 创建一个包含当月所有日期的字典，值为未完成任务计数（初始为0）
        var dailyStats: [String: Int] = [:]
        
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthDate)!
        let firstDayComponents = calendar.dateComponents([.year, .month], from: monthDate)
        
        // 调试：打印任务列表
        print("正在处理的任务数量: \(tasks.count)")
        for (index, task) in tasks.enumerated() {
            print("任务[\(index)]: ID=\(task.id), 标题=\(task.title), 创建日期=\(task.createdAt)")
        }
        
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
        
        // 调试：打印初始日期列表
        print("统计的日期列表: \(dailyStats.keys.sorted())")
        
        // 异步处理所有任务的记录
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            
            // 创建一个字典，用于跟踪每个日期每个任务的未完成状态
            var taskTracker: [String: Set<String>] = [:]
            for dateString in dailyStats.keys {
                taskTracker[dateString] = Set<String>()
            }
            
            // 日期格式化器，用于比较日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // ISO8601格式化器，用于解析任务创建日期和截止日期
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            // 为调试创建一个副本
            let targetDate = "2025-03-04"
            var debugTasksForDate: [String] = []

            for (taskIndex, task) in tasks.enumerated() {
                dispatchGroup.enter()
                
                // 获取任务的创建日期，并将其转换为Date对象
                let taskCreationDateString = task.createdAt
                
                // 尝试使用不同配置的ISO8601格式解析日期
                var taskCreationDate: Date
                
                // 首先尝试完全配置的ISO8601格式解析
                if let isoDate = isoFormatter.date(from: taskCreationDateString) {
                    taskCreationDate = isoDate
                    print("成功使用完整ISO8601格式解析日期: \(taskCreationDateString)")
                } else {
                    // 如果失败，尝试不带毫秒的ISO8601格式
                    let simpleIsoFormatter = ISO8601DateFormatter()
                    simpleIsoFormatter.formatOptions = [.withInternetDateTime]
                    
                    if let simpleIsoDate = simpleIsoFormatter.date(from: taskCreationDateString) {
                        taskCreationDate = simpleIsoDate
                        print("成功使用不带毫秒的ISO8601格式解析日期: \(taskCreationDateString)")
                    } else {
                        // 再尝试自定义格式
                        let customFormatter = DateFormatter()
                        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                        
                        if let customDate = customFormatter.date(from: taskCreationDateString) {
                            taskCreationDate = customDate
                            print("成功使用自定义格式解析日期: \(taskCreationDateString)")
                        } else {
                            // 最后尝试简单的日期格式
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                            if let formatterDate = dateFormatter.date(from: taskCreationDateString) {
                                taskCreationDate = formatterDate
                                print("成功使用简单日期格式解析日期: \(taskCreationDateString)")
                            } else {
                                // 如果都失败了，使用任务ID的哈希值生成一个稳定的默认日期
                                // 这样至少对于同一个任务，每次生成的默认日期都是一样的
                                print("无法解析任务创建日期: \(taskCreationDateString)，使用基于任务ID的默认日期")
                                let hashValue = abs(task.id.hashValue) % 1000
                                taskCreationDate = Calendar.current.date(byAdding: .day, value: -hashValue, to: Date()) ?? Date()
                            }
                        }
                    }
                }
                
                // 获取不带时间的创建日期（只保留年月日）
                let taskCreationDateComponents = calendar.dateComponents([.year, .month, .day], from: taskCreationDate)
                let taskCreationDateWithoutTime = calendar.date(from: taskCreationDateComponents) ?? taskCreationDate
                let formattedCreationDate = dateFormatter.string(from: taskCreationDateWithoutTime)
                
                // 解析任务截止日期（如果有）
                var taskDueDate: Date? = nil
                if let dueDateString = task.dueDate {
                    // 尝试使用各种格式解析截止日期
                    if let isoDate = isoFormatter.date(from: dueDateString) {
                        taskDueDate = isoDate
                    } else {
                        let simpleIsoFormatter = ISO8601DateFormatter()
                        simpleIsoFormatter.formatOptions = [.withInternetDateTime]
                        
                        if let simpleIsoDate = simpleIsoFormatter.date(from: dueDateString) {
                            taskDueDate = simpleIsoDate
                        } else {
                            let customFormatter = DateFormatter()
                            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                            
                            if let customDate = customFormatter.date(from: dueDateString) {
                                taskDueDate = customDate
                            } else {
                                let simpleDateFormatter = DateFormatter()
                                simpleDateFormatter.dateFormat = "yyyy-MM-dd"
                                
                                if let simpleDate = simpleDateFormatter.date(from: dueDateString) {
                                    taskDueDate = simpleDate
                                }
                            }
                        }
                    }
                    
                    if let dueDate = taskDueDate {
                        let dueDateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
                        taskDueDate = calendar.date(from: dueDateComponents)
                        print("任务[\(taskIndex)] (\(task.title)) 截止日期: \(dateFormatter.string(from: taskDueDate!))")
                    } else {
                        print("无法解析任务[\(taskIndex)] (\(task.title)) 的截止日期: \(dueDateString)")
                    }
                }
                
                print("任务[\(taskIndex)] (\(task.title)) 创建日期: \(formattedCreationDate)")
                
                // 获取任务的所有记录
                self.fetchTaskRecordsForStats(taskId: task.id) { records in
                    print("任务[\(taskIndex)] (\(task.title)) 获取到 \(records.count) 条记录")
                    
                    // 打印记录详情
                    for (recordIndex, record) in records.enumerated() {
                        print("  记录[\(recordIndex)]: 日期=\(record.date), 状态=\(record.status)")
                    }
                    
                    // 处理记录，检查每个日期的状态
                    for dateString in dailyStats.keys {
                        // 将日期字符串转换为Date对象进行比较
                        guard let currentDate = dateFormatter.date(from: dateString) else {
                            continue
                        }
                        
                        // 检查当前日期是否超过了任务截止日期
                        // 如果任务有截止日期，并且当前日期已经超过了截止日期，那么不统计这个任务
                        if let dueDate = taskDueDate, currentDate > dueDate {
                            if dateString == targetDate {
                                print("日期 \(dateString) 已超过任务[\(taskIndex)] (\(task.title)) 的截止日期 \(dateFormatter.string(from: dueDate))，不计入统计")
                            }
                            continue
                        }
                        
                        // 只有当日期在任务创建日期之后或当天才统计
                        if currentDate >= taskCreationDateWithoutTime {
                            // 查找该日期的记录
                            let dateRecords = records.filter { $0.date == dateString }
                            
                            // 判断该日期的任务是否完成
                            if let record = dateRecords.first {
                                // 检查记录状态
                                if record.status == .approved {
                                    // 如果状态是已批准，该任务该日期视为已完成，不计入未完成统计
                                    if dateString == targetDate {
                                        print("日期 \(dateString) 的任务[\(taskIndex)] (\(task.title)) 已完成，不计入统计")
                                    }
                                } else {
                                    // 如果状态不是已批准（可能是submitted或rejected），标记该日期该任务为未完成
                                    taskTracker[dateString]?.insert(task.id)
                                    
                                    // 调试特定日期
                                    if dateString == targetDate {
                                        debugTasksForDate.append("任务[\(taskIndex)] \(task.title): 状态为\(record.status)，计为未完成")
                                    }
                                }
                            } else {
                                // 如果没有该日期的记录，表示未提交，标记该日期该任务为未完成
                                taskTracker[dateString]?.insert(task.id)
                                
                                // 调试特定日期
                                if dateString == targetDate {
                                    debugTasksForDate.append("任务[\(taskIndex)] \(task.title): 无记录，计为未完成")
                                }
                            }
                        } else {
                            if dateString == targetDate {
                                print("日期 \(dateString) 早于任务[\(taskIndex)] (\(task.title)) 的创建日期 \(formattedCreationDate)，不计入统计")
                            }
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // 打印特定日期的调试信息
                print("========== 日期 \(targetDate) 的未完成任务详情 ==========")
                print("未完成任务数量: \(taskTracker[targetDate]?.count ?? 0)")
                print("未完成任务列表:")
                for taskDetail in debugTasksForDate {
                    print("  - \(taskDetail)")
                }
                print("================================================")
                
                // 计算每个日期的未完成任务数量
                for dateString in dailyStats.keys {
                    dailyStats[dateString] = taskTracker[dateString]?.count ?? 0
                    print("日期 \(dateString) 的未完成任务数量: \(dailyStats[dateString]!), 任务ID: \(taskTracker[dateString]?.joined(separator: ", ") ?? "无")")
                }
                
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
        // 首先检查缓存中是否有该任务的记录
        let cachedRecords = self.allTaskRecords.filter { $0.taskId == taskId }
        
        // 立即使用缓存数据（如果有）
        if !cachedRecords.isEmpty {
            print("使用缓存的\(cachedRecords.count)条记录，同时在后台更新数据")
            // 立即返回缓存数据
            completion(cachedRecords)
        } else {
            print("缓存中没有任务[\(taskId)]的记录")
        }
        
        // 添加随机参数，确保不返回服务端缓存
        var urlParams: [String: String] = ["_nocache": UUID().uuidString]
        
        // 无论是否有缓存，都发起API请求获取最新数据
        apiService.fetchTaskRecords(taskId: taskId, urlParams: urlParams) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let records):
                // 打印获取到的记录条数以便调试
                print("从API获取任务[\(taskId)]记录: \(records.count)条")
                
                // 检查新记录是否与缓存记录不同
                let shouldUpdate = records.count != cachedRecords.count || 
                                   !self.areRecordsEqual(records, cachedRecords)
                
                if shouldUpdate {
                    // 更新缓存（替换该任务的所有旧记录）
                    DispatchQueue.main.async {
                        // 移除该任务的旧记录
                        self.allTaskRecords.removeAll { $0.taskId == taskId }
                        // 添加新记录
                        self.allTaskRecords.append(contentsOf: records)
                        print("已更新任务[\(taskId)]的记录缓存，共\(records.count)条记录")
                        
                        // 打印记录ID列表以便调试
                        let recordIds = records.map { $0.id }.joined(separator: ", ")
                        print("任务[\(taskId)]的记录IDs: \(recordIds)")
                        
                        // 如果之前缓存为空或数据有变化，则调用completion
                        if cachedRecords.isEmpty || shouldUpdate {
                            print("检测到数据变化，再次调用completion通知更新")
                            completion(records)
                        }
                    }
                } else {
                    print("任务[\(taskId)]的记录无变化，无需更新界面")
                }
            case .failure(let error):
                print("获取任务[\(taskId)]记录失败: \(error)")
                // API请求失败时，如果之前没有返回过缓存数据，则返回缓存
                if cachedRecords.isEmpty {
                    DispatchQueue.main.async {
                        completion(cachedRecords)
                    }
                }
            }
        }
    }
    
    // 辅助方法：比较两组记录是否相同
    private func areRecordsEqual(_ records1: [TaskRecord], _ records2: [TaskRecord]) -> Bool {
        // 如果数量不同，直接返回false
        if records1.count != records2.count {
            print("记录数量不同: \(records1.count) vs \(records2.count)")
            return false
        }
        
        // 为更详细的比较，创建记录ID到记录的映射
        let map1 = Dictionary(grouping: records1, by: { $0.id }).mapValues { $0.first! }
        let map2 = Dictionary(grouping: records2, by: { $0.id }).mapValues { $0.first! }
        
        // 首先检查ID集合是否相同
        let ids1 = Set(records1.map { $0.id })
        let ids2 = Set(records2.map { $0.id })
        
        if ids1 != ids2 {
            let missingInFirst = ids2.subtracting(ids1)
            let missingInSecond = ids1.subtracting(ids2)
            
            if !missingInFirst.isEmpty {
                print("第一组缺少记录: \(missingInFirst.joined(separator: ", "))")
            }
            
            if !missingInSecond.isEmpty {
                print("第二组缺少记录: \(missingInSecond.joined(separator: ", "))")
            }
            
            return false
        }
        
        // 详细比较每条记录的状态和日期
        for id in ids1 {
            let record1 = map1[id]!
            let record2 = map2[id]!
            
            if record1.status != record2.status || record1.date != record2.date {
                print("记录 \(id) 不同: 状态[\(record1.status) vs \(record2.status)], 日期[\(record1.date) vs \(record2.date)]")
                return false
            }
        }
        
        return true
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
        
        // 如果已有计算结果，先返回缓存的结果
        let hasCachedResult = self.totalFailedCount > 0
        if hasCachedResult {
            print("使用缓存的累计失败次数: \(self.totalFailedCount)，同时在后台更新")
            completion(self.totalFailedCount)
        } else {
            // 如果没有缓存的结果，设置加载状态
            isLoading = true
        }
        
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
            
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                // 检查是否与缓存的结果不同
                if self.totalFailedCount != totalFailed {
                    print("更新累计失败次数: \(totalFailed) (原值: \(self.totalFailedCount))")
                    self.totalFailedCount = totalFailed
                    
                    // 如果之前没有缓存结果或结果有变化，通知调用方
                    if !hasCachedResult {
                        print("首次计算累计失败次数，通知UI更新")
                        completion(totalFailed)
                    } else {
                        print("累计失败次数有变化，通知UI更新")
                        completion(totalFailed)
                    }
                } else {
                    print("累计失败次数无变化: \(totalFailed)")
                    if !hasCachedResult {
                        // 如果之前没有缓存结果，通知调用方
                        print("首次计算累计失败次数，但值未变，仍通知UI更新")
                        completion(totalFailed)
                    }
                }
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
