import Foundation
import SwiftUI

// 新增：CharacterStory模型
struct CharacterStory: Identifiable, Codable {
    let id: String
    let userId: String
    let characterName: String
    let content: String
    let createdAt: String
    let dreamsCount: Int
}

class DreamViewModel: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    // AI功能相关状态
    @Published var isInterpretationLoading = false
    @Published var currentInterpretation: DreamInterpretation?
    @Published var currentContinuation: DreamContinuation?
    @Published var currentPrediction: DreamPrediction?
    
    // 新增：梦境报告相关状态
    @Published var currentReport: DreamReport?
    @Published var isReportLoading = false
    
    // 添加报告历史列表
    @Published var reportHistory: [DreamReport] = []
    
    // 人物志相关状态
    @Published var isCharacterStoryLoading = false
    @Published var currentCharacterStory: CharacterStory?
    
    private let apiService = APIService.shared
    private let deepSeekService = DeepSeekService.shared
    
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
        
        // 加载报告历史记录
        loadReportHistoryFromLocal()
        
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
    
    // MARK: - AI功能
    
    // 解析梦境
    func interpretDream(dream: Dream, style: DeepSeekStyle, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始解梦: \(dream.id), 风格: \(style.rawValue)")
        
        deepSeekService.interpretDream(content: dream.content, style: style) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let content):
                    print("解梦成功，获取内容长度: \(content.count)字符")
                    
                    // 创建解梦结果
                    let interpretation = DreamInterpretation(
                        id: UUID().uuidString,
                        dreamId: dream.id,
                        style: style.rawValue,
                        content: content,
                        createdAt: ISO8601DateFormatter().string(from: Date())
                    )
                    self.currentInterpretation = interpretation
                    print("创建解梦结果对象: \(interpretation.id)")
                    
                    // 调用API保存解梦结果
                    print("正在保存解梦结果到服务器...")
                    self.saveDreamInterpretation(dreamId: dream.id, interpretation: interpretation) { success in
                        print("保存解梦结果: \(success ? "成功" : "失败")")
                        
                        if success {
                            // 直接更新当前显示的梦境对象
                            if let index = self.dreams.firstIndex(where: { $0.id == dream.id }) {
                                var updatedDream = self.dreams[index]
                                if updatedDream.dreamInterpretations == nil {
                                    updatedDream.dreamInterpretations = []
                                }
                                updatedDream.dreamInterpretations?.append(interpretation)
                                self.dreams[index] = updatedDream
                                print("本地更新梦境对象，添加解梦结果")
                            }
                        }
                        
                        completion(success)
                    }
                    
                case .failure(let error):
                    print("解梦失败: \(error.localizedDescription)")
                    self.errorMessage = "解梦失败: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // 续写梦境
    func continueDream(dream: Dream, style: DeepSeekStyle, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始续写梦境: \(dream.id), 风格: \(style.rawValue)")
        
        deepSeekService.continueDream(content: dream.content, style: style) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let content):
                    print("续写成功，获取内容长度: \(content.count)字符")
                    
                    // 创建续写结果
                    let continuation = DreamContinuation(
                        id: UUID().uuidString,
                        dreamId: dream.id,
                        style: style.rawValue,
                        content: content,
                        createdAt: ISO8601DateFormatter().string(from: Date())
                    )
                    self.currentContinuation = continuation
                    print("创建续写结果对象: \(continuation.id)")
                    
                    // 调用API保存续写结果
                    print("正在保存续写结果到服务器...")
                    self.saveDreamContinuation(dreamId: dream.id, continuation: continuation) { success in
                        print("保存续写结果: \(success ? "成功" : "失败")")
                        
                        if success {
                            // 直接更新当前显示的梦境对象
                            if let index = self.dreams.firstIndex(where: { $0.id == dream.id }) {
                                var updatedDream = self.dreams[index]
                                if updatedDream.dreamContinuations == nil {
                                    updatedDream.dreamContinuations = []
                                }
                                updatedDream.dreamContinuations?.append(continuation)
                                self.dreams[index] = updatedDream
                                print("本地更新梦境对象，添加续写结果")
                            }
                        }
                        
                        completion(success)
                    }
                    
                case .failure(let error):
                    print("续写失败: \(error.localizedDescription)")
                    self.errorMessage = "续写失败: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // 预测未来
    func predictFromDream(id: String, style: DeepSeekStyle = .predictToday, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始预测梦境: \(id), 时间范围: \(style.rawValue)")
        
        // 查找梦境对象
        guard let dream = dreams.first(where: { $0.id == id }) else {
            errorMessage = "未找到梦境内容"
            isLoading = false
            completion(false)
            return
        }
        
        deepSeekService.predictFromDream(content: dream.content, style: style) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let content):
                    print("预测成功，获取内容长度: \(content.count)字符")
                    
                    // 创建预测结果
                    let prediction = DreamPrediction(
                        id: UUID().uuidString,
                        dreamId: id,
                        content: content,
                        createdAt: ISO8601DateFormatter().string(from: Date()),
                        style: style.rawValue // 保存预言的时间范围
                    )
                    self.currentPrediction = prediction
                    print("创建预测结果对象: \(prediction.id)")
                    
                    // 调用API保存预测结果
                    print("正在保存预测结果到服务器...")
                    self.saveDreamPrediction(dreamId: id, prediction: prediction) { success in
                        print("保存预测结果: \(success ? "成功" : "失败")")
                        
                        if success {
                            // 直接更新当前显示的梦境对象
                            if let index = self.dreams.firstIndex(where: { $0.id == id }) {
                                var updatedDream = self.dreams[index]
                                if updatedDream.dreamPredictions == nil {
                                    updatedDream.dreamPredictions = []
                                }
                                updatedDream.dreamPredictions?.append(prediction)
                                self.dreams[index] = updatedDream
                                print("本地更新梦境对象，添加预测结果")
                            }
                        }
                        
                        completion(success)
                    }
                    
                case .failure(let error):
                    print("预测失败: \(error.localizedDescription)")
                    self.errorMessage = "预测失败: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // 保存解梦结果
    private func saveDreamInterpretation(dreamId: String, interpretation: DreamInterpretation, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 构建请求体
        let requestData: [String: Any] = [
            "dream_id": dreamId,
            "style": interpretation.style,
            "content": interpretation.content
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            errorMessage = "数据序列化失败"
            isLoading = false
            completion(false)
            return
        }
        
        // 调用API保存解梦结果
        apiService.request(endpoint: "dream_interpretations", method: "POST", body: jsonData) { [weak self] (result: Result<DreamInterpretation, APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedInterpretation):
                    // 更新当前解梦结果ID
                    self?.currentInterpretation = savedInterpretation
                    
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        if updatedDream?.dreamInterpretations == nil {
                            updatedDream?.dreamInterpretations = []
                        }
                        updatedDream?.dreamInterpretations?.append(savedInterpretation)
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 保存续写结果
    private func saveDreamContinuation(dreamId: String, continuation: DreamContinuation, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 构建请求体
        let requestData: [String: Any] = [
            "dream_id": dreamId,
            "style": continuation.style,
            "content": continuation.content
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            errorMessage = "数据序列化失败"
            isLoading = false
            completion(false)
            return
        }
        
        // 调用API保存续写结果
        apiService.request(endpoint: "dream_continuations", method: "POST", body: jsonData) { [weak self] (result: Result<DreamContinuation, APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedContinuation):
                    // 更新当前续写结果ID
                    self?.currentContinuation = savedContinuation
                    
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        if updatedDream?.dreamContinuations == nil {
                            updatedDream?.dreamContinuations = []
                        }
                        updatedDream?.dreamContinuations?.append(savedContinuation)
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 保存预测结果
    private func saveDreamPrediction(dreamId: String, prediction: DreamPrediction, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 构建请求体
        let requestData: [String: Any] = [
            "dream_id": dreamId,
            "content": prediction.content
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            errorMessage = "数据序列化失败"
            isLoading = false
            completion(false)
            return
        }
        
        // 调用API保存预测结果
        apiService.request(endpoint: "dream_predictions", method: "POST", body: jsonData) { [weak self] (result: Result<DreamPrediction, APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedPrediction):
                    // 更新当前预测结果ID
                    self?.currentPrediction = savedPrediction
                    
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        if updatedDream?.dreamPredictions == nil {
                            updatedDream?.dreamPredictions = []
                        }
                        updatedDream?.dreamPredictions?.append(savedPrediction)
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 获取梦境解梦历史
    func fetchDreamInterpretations(dreamId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        apiService.request(endpoint: "dream_interpretations?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamInterpretation], APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let interpretations):
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        updatedDream?.dreamInterpretations = interpretations
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 获取梦境续写历史
    func fetchDreamContinuations(dreamId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        apiService.request(endpoint: "dream_continuations?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamContinuation], APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let continuations):
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        updatedDream?.dreamContinuations = continuations
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 获取梦境预测历史
    func fetchDreamPredictions(dreamId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        apiService.request(endpoint: "dream_predictions?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamPrediction], APIError>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let predictions):
                    // 找到并更新梦境对象
                    if let index = self?.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self?.dreams[index]
                        updatedDream?.dreamPredictions = predictions
                        if let dream = updatedDream {
                            self?.dreams[index] = dream
                        }
                    }
                    completion(true)
                case .failure(let error):
                    self?.handleError(error)
                    completion(false)
                }
            }
        }
    }
    
    // 加载梦境所有AI内容
    func loadDreamAIContent(dreamId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("开始加载梦境AI内容: \(dreamId)")
        
        let group = DispatchGroup()
        var allSuccess = true
        
        // 获取解梦历史
        group.enter()
        print("正在获取解梦历史...")
        apiService.request(endpoint: "dream_interpretations?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamInterpretation], APIError>) in
            DispatchQueue.main.async {
                guard let self = self else { group.leave(); return }
                
                switch result {
                case .success(let interpretations):
                    print("成功获取解梦历史: \(interpretations.count)条记录")
                    // 直接更新当前显示的梦境对象
                    if let index = self.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self.dreams[index]
                        updatedDream.dreamInterpretations = interpretations
                        self.dreams[index] = updatedDream
                    }
                case .failure(let error):
                    print("获取解梦历史失败: \(error)")
                    self.handleError(error)
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        // 获取续写历史
        group.enter()
        print("正在获取续写历史...")
        apiService.request(endpoint: "dream_continuations?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamContinuation], APIError>) in
            DispatchQueue.main.async {
                guard let self = self else { group.leave(); return }
                
                switch result {
                case .success(let continuations):
                    print("成功获取续写历史: \(continuations.count)条记录")
                    // 直接更新当前显示的梦境对象
                    if let index = self.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self.dreams[index]
                        updatedDream.dreamContinuations = continuations
                        self.dreams[index] = updatedDream
                    }
                case .failure(let error):
                    print("获取续写历史失败: \(error)")
                    self.handleError(error)
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        // 获取预测历史
        group.enter()
        print("正在获取预测历史...")
        apiService.request(endpoint: "dream_predictions?dream_id=\(dreamId)", method: "GET") { [weak self] (result: Result<[DreamPrediction], APIError>) in
            DispatchQueue.main.async {
                guard let self = self else { group.leave(); return }
                
                switch result {
                case .success(let predictions):
                    print("成功获取预测历史: \(predictions.count)条记录")
                    // 直接更新当前显示的梦境对象
                    if let index = self.dreams.firstIndex(where: { $0.id == dreamId }) {
                        var updatedDream = self.dreams[index]
                        updatedDream.dreamPredictions = predictions
                        self.dreams[index] = updatedDream
                    }
                case .failure(let error):
                    print("获取预测历史失败: \(error)")
                    self.handleError(error)
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            print("所有AI内容加载完成，结果: \(allSuccess ? "成功" : "部分失败")")
            completion(allSuccess)
        }
    }
    
    // 新增：筛选指定时间范围内的梦境
    func filterDreamsByTimeRange(_ timeRange: AnalysisTimeRange) -> [Dream] {
        let calendar = Calendar.current
        let today = Date()
        let pastDate: Date
        
        switch timeRange {
        case .week:
            pastDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .month:
            pastDate = calendar.date(byAdding: .day, value: -30, to: today)!
        case .quarter:
            pastDate = calendar.date(byAdding: .day, value: -90, to: today)!
        case .halfYear:
            pastDate = calendar.date(byAdding: .day, value: -180, to: today)!
        case .year:
            pastDate = calendar.date(byAdding: .day, value: -365, to: today)!
        }
        
        // 问题修复：打印时间范围的日志以便调试
        print("时间范围筛选: 从 \(pastDate) 到 \(today)")
        
        // 修复：添加对日期解析失败的调试信息
        let filteredDreams = dreams.filter { dream in
            if let dreamDate = formatDateToDate(dream.date) {
                let isInRange = dreamDate >= pastDate && dreamDate <= today
                print("梦境日期: \(dream.date), 解析后: \(dreamDate), 是否在范围内: \(isInRange)")
                return isInRange
            } else {
                print("⚠️ 日期解析失败: \(dream.date)")
                return false
            }
        }.sorted(by: { $0.date < $1.date }) // 按时间升序排序，从早到晚
        
        print("筛选后的梦境数量: \(filteredDreams.count)")
        return filteredDreams
    }
    
    // 新增：生成人物志故事
    func generateCharacterStory(characterName: String, completion: @escaping (Bool) -> Void) {
        // 获取所有梦境记录
        let allDreams = self.dreams
        
        if allDreams.isEmpty {
            print("错误: 没有梦境记录")
            errorMessage = "没有梦境记录"
            completion(false)
            return
        }
        
        isCharacterStoryLoading = true
        
        print("开始生成人物志，关注的人物: \(characterName)")
        
        // 调用DeepSeek服务生成人物志
        deepSeekService.generateCharacterStory(dreams: allDreams, characterName: characterName) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCharacterStoryLoading = false
                
                switch result {
                case .success(let storyContent):
                    print("人物志生成成功，内容长度: \(storyContent.count)字符")
                    
                    // 创建人物志结果
                    let characterStory = CharacterStory(
                        id: UUID().uuidString,
                        userId: "", // 实际应用中应填充用户ID
                        characterName: characterName,
                        content: storyContent,
                        createdAt: self.getCurrentDateString(),
                        dreamsCount: allDreams.count
                    )
                    
                    self.currentCharacterStory = characterStory
                    completion(true)
                    
                    // 将人物志也保存为报告历史
                    let report = DreamReport(
                        id: UUID().uuidString,
                        userId: "",
                        reportType: "character",
                        content: storyContent,
                        createdAt: self.getCurrentDateString(),
                        dreamsCount: allDreams.count,
                        startDate: allDreams.first?.date ?? "",
                        endDate: allDreams.last?.date ?? ""
                    )
                    self.saveReportToHistory(report)
                    
                case .failure(let error):
                    print("人物志生成失败: \(error.localizedDescription)")
                    self.errorMessage = "生成人物志失败: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // 新增：生成梦境报告
    func generateDreamReport(completion: @escaping (Bool) -> Void) {
        let settings = UserSettings.load()
        let reportTimeRange = settings.dreamReportTimeRange
        
        print("开始生成梦境报告，选择的时间范围: \(reportTimeRange.displayName)")
        
        // 根据报告类型确定时间范围
        let calendar = Calendar.current
        let today = Date()
        let pastDate: Date
        
        switch reportTimeRange {
        case .week:
            pastDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .month:
            pastDate = calendar.date(byAdding: .month, value: -1, to: today)!
        case .year:
            pastDate = calendar.date(byAdding: .year, value: -1, to: today)!
        }
        
        print("报告时间范围: 从 \(pastDate) 到 \(today)")
        
        // 筛选时间范围内的梦境
        let filteredDreams = dreams.compactMap { dream -> Dream? in
            guard let dreamDate = formatDateToDate(dream.date) else {
                print("⚠️ 梦境报告 - 日期解析失败: \(dream.date)")
                return nil
            }
            let isInRange = dreamDate >= pastDate && dreamDate <= today
            print("梦境日期: \(dream.date), 解析后: \(dreamDate), 是否在范围内: \(isInRange)")
            return isInRange ? dream : nil
        }.sorted(by: { $0.date < $1.date }) // 按时间升序排序
        
        print("筛选后的梦境数量: \(filteredDreams.count)")
        
        if filteredDreams.isEmpty {
            print("错误: 所选时间范围内没有梦境记录")
            errorMessage = "所选时间范围内没有梦境记录"
            completion(false)
            return
        }
        
        isReportLoading = true
        
        // 获取时间范围的开始和结束日期
        let startDate = filteredDreams.first?.date ?? ""
        let endDate = filteredDreams.last?.date ?? ""
        
        // 调用DeepSeek服务生成报告
        deepSeekService.generateDreamReport(dreams: filteredDreams, reportStyle: reportTimeRange) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isReportLoading = false
                
                switch result {
                case .success(let reportContent):
                    // 创建报告结果
                    let report = DreamReport(
                        id: UUID().uuidString,
                        userId: "", // 实际应用中应填充用户ID
                        reportType: reportTimeRange.rawValue,
                        content: reportContent,
                        createdAt: self.getCurrentDateString(),
                        dreamsCount: filteredDreams.count,
                        startDate: startDate,
                        endDate: endDate
                    )
                    
                    self.currentReport = report
                    completion(true)
                    
                    // 保存到报告历史中
                    self.saveReportToHistory(report)
                    
                case .failure(let error):
                    self.errorMessage = "生成报告失败: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // 新增：保存报告到历史记录
    private func saveReportToHistory(_ report: DreamReport) {
        // 添加到内存中的历史记录
        reportHistory.append(report)
        
        // 保存到本地存储
        self.saveReportHistoryToLocal()
        
        print("报告已保存到历史记录，当前历史记录数量: \(reportHistory.count)")
    }
    
    // 新增：保存报告历史到本地存储
    private func saveReportHistoryToLocal() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reportHistory) {
            UserDefaults.standard.set(encoded, forKey: "dreamReportHistory")
        } else {
            print("保存报告历史到本地失败")
        }
    }
    
    // 新增：从本地存储加载报告历史
    func loadReportHistoryFromLocal() {
        if let data = UserDefaults.standard.data(forKey: "dreamReportHistory") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([DreamReport].self, from: data) {
                reportHistory = decoded
                print("已从本地加载\(reportHistory.count)条报告历史")
            } else {
                print("解码报告历史失败")
                reportHistory = []
            }
        } else {
            print("本地无保存的报告历史")
            reportHistory = []
        }
    }
    
    // 辅助方法：获取当前日期字符串
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.string(from: Date())
    }
    
    // 辅助方法：将日期字符串转换为Date对象
    private func formatDateToDate(_ dateString: String) -> Date? {
        // 首先尝试标准ISO格式
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        // 尝试多种可能的日期格式
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        print("无法解析日期: \(dateString)")
        return nil
    }
}
