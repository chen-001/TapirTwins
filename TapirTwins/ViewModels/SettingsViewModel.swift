import Foundation
import SwiftUI
import UserNotifications

class SettingsViewModel: ObservableObject {
    @Published var defaultShareSpaceId: String?
    @Published var dreamReminderEnabled: Bool = true
    @Published var dreamReminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var interpretationLength: Int = 400
    @Published var continuationLength: Int = 400
    @Published var predictionLength: Int = 400
    @Published var dreamAnalysisTimeRange: AnalysisTimeRange = .month
    @Published var dreamReportTimeRange: ReportTimeRange = .month
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        // 从本地加载设置
        let settings = UserSettings.load()
        self.defaultShareSpaceId = settings.defaultShareSpaceId
        self.dreamReminderEnabled = settings.dreamReminderEnabled
        self.dreamReminderTime = settings.dreamReminderTime
        self.interpretationLength = settings.interpretationLength
        self.continuationLength = settings.continuationLength
        self.predictionLength = settings.predictionLength
        self.dreamAnalysisTimeRange = settings.dreamAnalysisTimeRange
        self.dreamReportTimeRange = settings.dreamReportTimeRange
        
        // 检查通知权限
        checkNotificationPermission()
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
                    if let reminderEnabled = settings.dreamReminderEnabled {
                        self?.dreamReminderEnabled = reminderEnabled
                    }
                    if let reminderTime = settings.dreamReminderTime {
                        self?.dreamReminderTime = reminderTime
                    }
                    if let interpretationLength = settings.interpretationLength {
                        self?.interpretationLength = interpretationLength
                    }
                    if let continuationLength = settings.continuationLength {
                        self?.continuationLength = continuationLength
                    }
                    if let predictionLength = settings.predictionLength {
                        self?.predictionLength = predictionLength
                    }
                    if let analysisTimeRange = settings.dreamAnalysisTimeRange {
                        self?.dreamAnalysisTimeRange = analysisTimeRange
                    }
                    if let reportTimeRange = settings.dreamReportTimeRange {
                        self?.dreamReportTimeRange = reportTimeRange
                    }
                    
                    // 更新本地存储
                    var userSettings = UserSettings.load()
                    userSettings.defaultShareSpaceId = settings.defaultShareSpaceId
                    if let reminderEnabled = settings.dreamReminderEnabled {
                        userSettings.dreamReminderEnabled = reminderEnabled
                    }
                    if let reminderTime = settings.dreamReminderTime {
                        userSettings.dreamReminderTime = reminderTime
                    }
                    if let interpretationLength = settings.interpretationLength {
                        userSettings.interpretationLength = interpretationLength
                    }
                    if let continuationLength = settings.continuationLength {
                        userSettings.continuationLength = continuationLength
                    }
                    if let predictionLength = settings.predictionLength {
                        userSettings.predictionLength = predictionLength
                    }
                    if let analysisTimeRange = settings.dreamAnalysisTimeRange {
                        userSettings.dreamAnalysisTimeRange = analysisTimeRange
                    }
                    if let reportTimeRange = settings.dreamReportTimeRange {
                        userSettings.dreamReportTimeRange = reportTimeRange
                    }
                    userSettings.save()
                    
                    // 如果启用了提醒，则更新通知
                    if let reminderEnabled = settings.dreamReminderEnabled, reminderEnabled {
                        self?.scheduleDreamReminder()
                    } else {
                        self?.cancelDreamReminder()
                    }
                    
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
    
    func updateDreamReminderSettings(enabled: Bool, time: Date) {
        self.dreamReminderEnabled = enabled
        self.dreamReminderTime = time
        
        // 更新本地设置
        var userSettings = UserSettings.load()
        userSettings.dreamReminderEnabled = enabled
        userSettings.dreamReminderTime = time
        userSettings.save()
        
        // 更新服务器设置
        let settings = UserSettingsRequest(
            defaultShareSpaceId: defaultShareSpaceId,
            dreamReminderEnabled: enabled,
            dreamReminderTime: time
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateUserSettings(settings: settings) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 成功更新后，重新调度通知
                    if enabled {
                        self?.scheduleDreamReminder()
                    } else {
                        self?.cancelDreamReminder()
                    }
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    // 请求通知权限
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    completion(true)
                    // 如果用户启用了梦境提醒，则立即调度
                    if self.dreamReminderEnabled {
                        self.scheduleDreamReminder()
                    }
                } else {
                    completion(false)
                    // 如果权限被拒绝，禁用提醒设置
                    self.dreamReminderEnabled = false
                    
                    // 更新本地设置
                    var userSettings = UserSettings.load()
                    userSettings.dreamReminderEnabled = false
                    userSettings.save()
                }
            }
        }
    }
    
    // 检查通知权限
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    // 权限已授予，如果用户启用了梦境提醒，则调度
                    if self.dreamReminderEnabled {
                        self.scheduleDreamReminder()
                    }
                }
            }
        }
    }
    
    // 调度梦境提醒通知
    func scheduleDreamReminder() {
        // 取消现有的提醒
        cancelDreamReminder()
        
        // 获取提醒时间的小时和分钟
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dreamReminderTime)
        guard let hour = components.hour, let minute = components.minute else { return }
        
        // 创建触发器，每天在指定时间触发
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "记录梦境"
        content.body = "早上好，记得记录昨晚的梦境吗？"
        content.sound = UNNotificationSound.default
        
        // 支持灵动岛
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            
            if #available(iOS 16.0, *) {
                content.relevanceScore = 1.0 // 提高重要性评分到最高
            }
        }
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "dreamReminder",
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加梦境提醒通知失败: \(error.localizedDescription)")
            } else {
                print("成功添加梦境提醒通知")
                
                // 启动灵动岛活动
                if #available(iOS 16.1, *) {
                    // 获取明天的提醒时间作为显示
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    let tomorrowReminderTime = Calendar.current.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: tomorrow
                    ) ?? tomorrow
                    
                    // 测试当前时间的提醒（仅为了测试）
                    let testTime = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
                    
                    // 启动灵动岛活动，使用测试时间进行测试
                    DreamReminderActivityManager.shared.startDreamReminderActivity(
                        reminderTime: testTime, // 用于测试，实际使用时改回tomorrowReminderTime
                        message: "点击记录昨晚的梦境"
                    )
                    
                    // 测试完成后可以恢复为正常时间
                    // 注意：上线版本请使用下面的代码而不是上面的测试代码
                    // DreamReminderActivityManager.shared.startDreamReminderActivity(
                    //     reminderTime: tomorrowReminderTime,
                    //     message: "点击记录昨晚的梦境"
                    // )
                }
            }
        }
    }
    
    // 取消梦境提醒通知
    func cancelDreamReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dreamReminder"])
        
        // 停止灵动岛活动
        if #available(iOS 16.1, *) {
            DreamReminderActivityManager.shared.stopDreamReminderActivity()
        }
    }
    
    // 更新AI输出字数设置
    func updateAIOutputLengths(interpretation: Int, continuation: Int, prediction: Int) {
        self.interpretationLength = interpretation
        self.continuationLength = continuation
        self.predictionLength = prediction
        
        // 更新本地设置
        var userSettings = UserSettings.load()
        userSettings.interpretationLength = interpretation
        userSettings.continuationLength = continuation
        userSettings.predictionLength = prediction
        userSettings.save()
        
        // 更新服务器设置
        let settings = UserSettingsRequest(
            defaultShareSpaceId: defaultShareSpaceId,
            dreamReminderEnabled: dreamReminderEnabled,
            dreamReminderTime: dreamReminderTime,
            interpretationLength: interpretation,
            continuationLength: continuation,
            predictionLength: prediction
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateUserSettings(settings: settings) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 成功更新
                    print("AI输出字数设置更新成功")
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    // 新增：更新梦境分析时间范围
    func updateDreamAnalysisTimeRange(timeRange: AnalysisTimeRange) {
        self.dreamAnalysisTimeRange = timeRange
        
        // 更新本地设置
        var userSettings = UserSettings.load()
        userSettings.dreamAnalysisTimeRange = timeRange
        userSettings.save()
        
        // 更新服务器设置
        let settings = UserSettingsRequest(
            dreamAnalysisTimeRange: timeRange
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateUserSettings(settings: settings) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 成功更新
                    print("成功更新梦境分析时间范围")
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    // 新增：更新梦境报告时间范围
    func updateDreamReportTimeRange(timeRange: ReportTimeRange) {
        self.dreamReportTimeRange = timeRange
        
        // 更新本地设置
        var userSettings = UserSettings.load()
        userSettings.dreamReportTimeRange = timeRange
        userSettings.save()
        
        // 更新服务器设置
        let settings = UserSettingsRequest(
            dreamReportTimeRange: timeRange
        )
        
        isLoading = true
        errorMessage = nil
        
        apiService.updateUserSettings(settings: settings) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    // 成功更新
                    print("成功更新梦境报告类型")
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